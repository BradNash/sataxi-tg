const {
  CodeCommitClient,
  GetFileCommand,
} = require("@aws-sdk/client-codecommit");
const {
  BatchClient,
  DescribeJobDefinitionsCommand,
  RegisterJobDefinitionCommand,
  SubmitJobCommand,
  DeregisterJobDefinitionCommand,
} = require("@aws-sdk/client-batch");
const { STSClient, AssumeRoleCommand } = require("@aws-sdk/client-sts");
const {
  CodePipelineClient,
  PutJobFailureResultCommand,
  PutJobSuccessResultCommand,
} = require("@aws-sdk/client-codepipeline");
const {
  CloudWatchEventsClient,
  ListTargetsByRuleCommand,
  PutTargetsCommand,
} = require("@aws-sdk/client-cloudwatch-events");
const yaml = require("js-yaml");

const crossAccountRoleArn = process.env.CROSS_ACCOUNT_ROLE_ARN || null;

exports.handler = async (event, context) => {
  let jobId = event["CodePipeline.job"].id;

  const userParameters = JSON.parse(
    event["CodePipeline.job"].data.actionConfiguration.configuration
      .UserParameters
  );

  let jobDefinitionName = userParameters.JOB_DEFINITION;
  let jobQueueName = userParameters.JOB_QUEUE;
  let containerPropertiesFilePath =
    userParameters.CONTAINER_PROPERTIES_FILE_PATH;
  let repositoryName = userParameters.REPOSITORY_NAME;
  let commitHash = userParameters.COMMIT_HASH;
  let imageTag = userParameters.IMAGE_TAG;
  let cronSchedulingEnabled = userParameters.CRON_SCHEDULING_ENABLED;

  console.log(`Job Queue Name: ${jobQueueName}`);
  console.log(`Job Definition Name: ${jobDefinitionName}`);
  console.log(`Container Properties File Path: ${containerPropertiesFilePath}`);
  console.log(`Repository Name: ${repositoryName}`);
  console.log(`Commit Hash: ${commitHash}`);
  console.log(`Image Tag: ${imageTag}`);

  try {
    let crossAccountCredentials = crossAccountRoleArn
      ? await getCrossAccountCredentials(crossAccountRoleArn)
      : null;

    let containerPropertiesFile = await getCodeCommitFile(
      repositoryName,
      commitHash,
      containerPropertiesFilePath
    );

    containerPropertiesFile = containerPropertiesFile.replace(
      new RegExp("\\$\\{(IMAGE_TAG)\\}", "g"),
      imageTag
    );

    let newContainerProperties = yaml.load(containerPropertiesFile);

    let jobDefinition = await getJobDefinition(
      jobDefinitionName,
      crossAccountCredentials
    );

    delete jobDefinition.jobDefinitionArn;
    let oldJobDefinitionRevision = jobDefinition.revision;
    delete jobDefinition.revision;
    delete jobDefinition.status;
    delete jobDefinition.timeout;
    let oldTaskRegisteredBy = null;

    if (jobDefinition.tags.hasOwnProperty("registeredBy"))
      oldTaskRegisteredBy = jobDefinition.tags.registeredBy;

    jobDefinition.tags.registeredBy = context.functionName;

    for (let key in newContainerProperties) {
      if (newContainerProperties.hasOwnProperty(key)) {
        jobDefinition.containerProperties[key] = newContainerProperties[key];
      }
    }
    let newJobDefinitionRevision = await registerJobDefinition(
      jobDefinition,
      crossAccountCredentials
    );

    if (cronSchedulingEnabled) {
      await updateEventBridgeSchedulingRule(
        `${jobDefinitionName}-schedule`,
        `${jobDefinitionName}`,
        newJobDefinitionRevision,
        crossAccountCredentials
      );
    } else {
      await submitJob(
        `${jobDefinitionName}`,
        `${jobDefinitionName}:${newJobDefinitionRevision}`,
        jobQueueName,
        crossAccountCredentials
      );
    }

    if (oldTaskRegisteredBy == context.functionName) {
      await deregisterJobDefinition(
        `${jobDefinitionName}:${oldJobDefinitionRevision}`,
        crossAccountCredentials
      );
    }

    await putJobSuccess(jobId);
    context.succeed(
      `Successfully schedules ${jobDefinitionName} job with to ${jobQueueName} job queue`
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

const getJobDefinition = async (jobDefinitionName, crossAccountCredentials) => {
  const client = crossAccountCredentials
    ? new BatchClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new BatchClient({ region: "af-south-1" });

  const params = {
    jobDefinitionName: jobDefinitionName,
    status: "ACTIVE",
  };
  const command = new DescribeJobDefinitionsCommand(params);

  try {
    let data = await client.send(command);
    let latestJobDefinition = data.jobDefinitions[0];
    data.jobDefinitions.forEach((jobDefinition) => {
      if (jobDefinition.revision > latestJobDefinition.revision) {
        latestJobDefinition = jobDefinition;
      }
    });
    console.log("Successfully fetched latest job definition");
    return latestJobDefinition;
  } catch (err) {
    console.error(
      `Error retrieving latest job definition for ${jobDefinitionName} job`
    );
    throw err;
  }
};

const registerJobDefinition = async (
  jobDefinition,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new BatchClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new BatchClient({ region: "af-south-1" });

  const command = new RegisterJobDefinitionCommand(jobDefinition);

  try {
    let data = await client.send(command);
    console.log(
      `Successfully registered ${jobDefinition.jobDefinitionName} job definition with revision ${data.revision}`
    );
    return data.revision;
  } catch (err) {
    console.error(
      `Error ocurred while registering ${jobDefinition.jobDefinitionName} job definition`
    );
    throw err;
  }
};

const deregisterJobDefinition = async (
  jobDefinition,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new BatchClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new BatchClient({ region: "af-south-1" });

  const params = {
    jobDefinition: jobDefinition,
  };
  const command = new DeregisterJobDefinitionCommand(params);
  try {
    await client.send(command);
    console.log(`Successfully deregistered ${jobDefinition} job definition`);
  } catch (err) {
    console.error(
      `Error ocurred while deregistering ${jobDefinition} job definition`
    );
    throw err;
  }
};

const submitJob = async (
  jobName,
  jobDefinition,
  jobQueue,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new BatchClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new BatchClient({ region: "af-south-1" });

  const params = {
    jobName: jobName,
    jobDefinition: jobDefinition,
    jobQueue: jobQueue,
  };
  const command = new SubmitJobCommand(params);
  try {
    await client.send(command);
    console.log(
      `Successfully submitted ${jobName} job definition with job ${jobDefinition.revision} to queue ${jobQueue}`
    );
  } catch (err) {
    console.error(
      `Error ocurred while submitting ${jobName} job to queue ${jobQueue}`
    );
    throw err;
  }
};

const updateEventBridgeSchedulingRule = async (
  rule,
  jobDefinitionName,
  jobDefinitionRevision,
  crossAccountCredentials
) => {
  const client = crossAccountCredentials
    ? new CloudWatchEventsClient({
        credentials: crossAccountCredentials,
        region: "af-south-1",
      })
    : new CloudWatchEventsClient({ region: "af-south-1" });

  let params = {
    Rule: rule,
    Limit: 1,
  };

  let command = new ListTargetsByRuleCommand(params);
  try {
    let data = await client.send(command);
    let targets = data.Targets;
    const idx = targets[0].BatchParameters.JobDefinition.indexOf(
      `${jobDefinitionName}:`
    );
    targets[0].BatchParameters.JobDefinition =
      targets[0].BatchParameters.JobDefinition.substring(0, idx) +
      `${jobDefinitionName}:${jobDefinitionRevision}`;

    params = {
      Rule: rule,
      Targets: targets,
    };
    command = new PutTargetsCommand(params);
    await client.send(command);
    console.log(
      `Successfully updated EventBridge scheduling rule target with job ${jobDefinitionName}:${jobDefinitionRevision}`
    );
  } catch (err) {
    console.error(
      `Error ocurred while updating EventBridge scheduling rule target with job ${jobDefinitionName}:${jobDefinitionRevision}`
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
