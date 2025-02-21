const {
  CodeCommitClient,
  GetFileCommand,
} = require("@aws-sdk/client-codecommit");
const { SSMClient, PutParameterCommand } = require("@aws-sdk/client-ssm");
const {
  ECSClient,
  UpdateServiceCommand,
  DeregisterTaskDefinitionCommand,
  DescribeTaskDefinitionCommand,
  RegisterTaskDefinitionCommand,
} = require("@aws-sdk/client-ecs");
const { STSClient, AssumeRoleCommand } = require("@aws-sdk/client-sts");
const {
  CodePipelineClient,
  PutJobFailureResultCommand,
  PutJobSuccessResultCommand,
} = require("@aws-sdk/client-codepipeline");
const yaml = require("js-yaml");

const crossAccountRoleArn = process.env.CROSS_ACCOUNT_ROLE_ARN || null;

exports.handler = async (event, context) => {
  let jobId = event["CodePipeline.job"].id;

  const userParameters = JSON.parse(
    event["CodePipeline.job"].data.actionConfiguration.configuration
      .UserParameters
  );

  let serviceName = userParameters.SERVICE_NAME;
  let clusterName = userParameters.CLUSTER_NAME;
  let env = userParameters.ENV;
  let taskDefinitionName = `${serviceName}-${env}`;
  let taskDefinitionFilePath = userParameters.TASK_DEFINITION_FILE_PATH;
  let configFilePath = userParameters.CONFIG_FILE_PATH;
  let repositoryName = userParameters.REPOSITORY_NAME;
  let commitHash = userParameters.COMMIT_HASH;
  let imageTag = userParameters.IMAGE_TAG;

  console.log(`Cluster Name: ${clusterName}`);
  console.log(`Service Name: ${serviceName}`);
  console.log(`Environment: ${env}`);
  console.log(`Task Definition Name: ${taskDefinitionName}`);
  console.log(`Task Definition File Path: ${taskDefinitionFilePath}`);
  console.log(`Config File Path: ${configFilePath}`);
  console.log(`Repository Name: ${repositoryName}`);
  console.log(`Commit Hash: ${commitHash}`);
  console.log(`Image Tag: ${imageTag}`);

  try {
    let crossAccountCredentials = crossAccountRoleArn
      ? await getCrossAccountCredentials(crossAccountRoleArn)
      : null;

    let configFile = await getCodeCommitFile(
      repositoryName,
      commitHash,
      configFilePath
    );

    await updateSsmParameter(
      `/${env}/service/${serviceName}/config`,
      configFile,
      `Service config for ${serviceName}-${env}`,
      crossAccountCredentials
    );

    let taskDefinitionFile = await getCodeCommitFile(
      repositoryName,
      commitHash,
      taskDefinitionFilePath
    );

    taskDefinitionFile = taskDefinitionFile.replace(
      new RegExp("\\$\\{(IMAGE_TAG)\\}", "g"),
      imageTag
    );

    let newTaskDefinition = yaml.load(taskDefinitionFile);

    if (!newTaskDefinition.hasOwnProperty("containerDefinitions")) {
      throw Error(
        `No containerDefinitions section in task definition - ${taskDefinitionFilePath}`
      );
    }

    newTaskDefinition.containerDefinitions.forEach((containerDefinition) => {
      if (containerDefinition.hasOwnProperty("logMultilinePattern")) {
        containerDefinition.logConfiguration = {
          logDriver: "awslogs",
          options: {
            "awslogs-group": `/${env}/service/${serviceName}`,
            "awslogs-region": "af-south-1",
            "awslogs-stream-prefix": env,
            "awslogs-multiline-pattern":
              containerDefinition.logMultilinePattern,
          },
        };
      } else {
        containerDefinition.logConfiguration = {
          logDriver: "awslogs",
          options: {
            "awslogs-group": `/${env}/service/${serviceName}`,
            "awslogs-region": "af-south-1",
            "awslogs-stream-prefix": env,
          },
        };
      }
    });

    let taskDefinition = await getTaskDefinition(
      taskDefinitionName,
      crossAccountCredentials
    );
    let oldTaskDefinitionRevision = taskDefinition.revision;
    delete taskDefinition.revision;
    delete taskDefinition.taskDefinitionArn;
    delete taskDefinition.status;
    delete taskDefinition.requiresAttributes;
    let oldTaskRegisteredBy = taskDefinition.registeredBy;
    delete taskDefinition.registeredBy;
    delete taskDefinition.registeredAt;
    delete taskDefinition.compatibilities;

    console.log(taskDefinition.taskRoleArn);

    taskDefinition.containerDefinitions =
      newTaskDefinition.containerDefinitions;

    if (newTaskDefinition.hasOwnProperty("volumes")) {
      taskDefinition.volumes = newTaskDefinition.volumes.map((volumeName) => {
        return {
          name: volumeName,
          host: {
            sourcePath: null,
          },
        };
      });
    }

    if (newTaskDefinition.hasOwnProperty("cpu")) {
      taskDefinition.cpu = newTaskDefinition.cpu;
    }

    if (newTaskDefinition.hasOwnProperty("memory")) {
      taskDefinition.memory = newTaskDefinition.memory;
    }

    let newTaskDefinitionRevision = await registerEcsTaskDefinition(
      taskDefinition,
      crossAccountCredentials
    );

    await updateEcsService(
      clusterName,
      serviceName,
      `${taskDefinitionName}:${newTaskDefinitionRevision}`,
      crossAccountCredentials
    );

    // DEREGISTER OLD TASK ONLY IF LAMBDA CREATED IT
    if (oldTaskRegisteredBy.includes(context.functionName)) {
      await deregisterEcsTaskDefinition(
        `${taskDefinitionName}:${oldTaskDefinitionRevision}`,
        crossAccountCredentials
      );
    }

    await putJobSuccess(jobId);
    context.succeed(
      `Successfully updated ${serviceName} in ${clusterName} cluster`
    );
  } catch (err) {
    console.error(err, err.stack);
    await putJobFailure(jobId, context.awsRequestId, err.stack);
    context.fail(err.stack);
  }
};

const getCodeCommitFile = async (repositoryName, commitHash, filePath) => {
  const client = new CodeCommitClient({ region: "eu-west-1" });

  const params = {
    filePath: filePath,
    repositoryName: repositoryName,
    commitSpecifier: commitHash,
  };
  const command = new GetFileCommand(params);

  try {
    let config = await client.send(command);
    return Buffer.from(config.fileContent, "base64").toString();
  } catch (err) {
    console.error(
      `Error fetching
        ${filePath} from
        ${repositoryName} CodeCommit repository with commit hash: ${commitHash}`
    );
    throw err;
  }
};

const updateSsmParameter = async (
  paramName,
  paramValue,
  paramDescription,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new SSMClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new SSMClient({ region: "af-south-1" });

  const params = {
    Name: paramName,
    Value: paramValue,
    Description: paramDescription,
    Type: "SecureString",
    Overwrite: true,
  };
  const command = new PutParameterCommand(params);

  try {
    await client.send(command);
  } catch (err) {
    console.error(`Error updating SSM parameter ${paramName}`);
    throw err;
  }
};

const getTaskDefinition = async (
  taskDefinitionName,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new ECSClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new ECSClient({ region: "af-south-1" });

  const params = {
    taskDefinition: taskDefinitionName,
  };
  const command = new DescribeTaskDefinitionCommand(params);

  try {
    let data = await client.send(command);
    console.log("Successfully fetched latest task definition");
    return data.taskDefinition;
  } catch (err) {
    console.error(`Error retrieving ${taskDefinitionName} task definition`);
    throw err;
  }
};

const registerEcsTaskDefinition = async (
  taskDefinition,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new ECSClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new ECSClient({ region: "af-south-1" });

  const command = new RegisterTaskDefinitionCommand(taskDefinition);

  try {
    let data = await client.send(command);
    console.log(
      `Successfully registered ${taskDefinition.family} task definition with revision ${data.taskDefinition.revision}`
    );
    return data.taskDefinition.revision;
  } catch (err) {
    console.error(
      `Error ocurred while registering ${taskDefinition.family} task definition`
    );
    throw err;
  }
};

const deregisterEcsTaskDefinition = async (
  taskDefinition,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new ECSClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new ECSClient({ region: "af-south-1" });

  const params = {
    taskDefinition: taskDefinition,
  };
  const command = new DeregisterTaskDefinitionCommand(params);

  try {
    await client.send(command);
    console.log(`Successfully deregistered ${taskDefinition} task definition`);
  } catch (err) {
    console.error(
      `Error ocurred while deregistering ${taskDefinition} task definition`
    );
    throw err;
  }
};

// Update and ECS Service with the specified task definition
const updateEcsService = async (
  clusterName,
  serviceName,
  taskDefinition,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new ECSClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new ECSClient({ region: "af-south-1" });

  const params = {
    cluster: clusterName,
    service: serviceName,
    taskDefinition: taskDefinition,
  };
  const command = new UpdateServiceCommand(params);

  try {
    await client.send(command);
    console.log(
      `Successfully updated ${serviceName} service in ${clusterName} cluster with task definition: ${taskDefinition}`
    );
  } catch (err) {
    console.error(
      `Error ocurred while updating ${serviceName} service in ${clusterName} cluster with task definition: ${taskDefinition}`
    );
    throw err;
  }
};

const getCrossAccountCredentials = async (roleArn) => {
  const client = new STSClient({
    region: "af-south-1",
  });

  const timestamp = new Date().getTime();
  const params = {
    RoleArn: roleArn,
    RoleSessionName: `deploy-lambda-cross-account-${timestamp}`,
  };
  const command = new AssumeRoleCommand(params);

  try {
    let data = await client.send(command);
    return {
      accessKeyId: data.Credentials.AccessKeyId,
      secretAccessKey: data.Credentials.SecretAccessKey,
      sessionToken: data.Credentials.SessionToken,
    };
  } catch (err) {
    console.error(`Error ocurred while assuming role ${roleArn}`);
    throw err;
  }
};

// Notify CodePipeline of a failed job
const putJobFailure = async (jobId, externalExecutionId, message) => {
  const client = new CodePipelineClient({ region: "eu-west-1" });

  const params = {
    jobId: jobId,
    failureDetails: {
      message: JSON.stringify(message),
      type: "JobFailed",
      externalExecutionId: externalExecutionId,
    },
  };
  const command = new PutJobFailureResultCommand(params);
  await client.send(command);
  console.log("Successfully put job failure");
};

// Notify CodePipeline of a successful job
const putJobSuccess = async (jobId) => {
  const client = new CodePipelineClient({ region: "eu-west-1" });

  const params = {
    jobId: jobId,
  };
  const command = new PutJobSuccessResultCommand(params);
  await client.send(command);
  console.log("Successfully put job success");
};
