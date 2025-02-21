const {
  ECSClient,
  ListTasksCommand,
  StopTaskCommand,
} = require("@aws-sdk/client-ecs");
const { STSClient, AssumeRoleCommand } = require("@aws-sdk/client-sts");
const {
  CodePipelineClient,
  PutJobFailureResultCommand,
  PutJobSuccessResultCommand,
} = require("@aws-sdk/client-codepipeline");

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

  console.log(`Cluster Name: ${clusterName}`);
  console.log(`Service Name: ${serviceName}`);
  console.log(`Environment: ${env}`);

  try {
    let crossAccountCredentials = crossAccountRoleArn
      ? await getCrossAccountCredentials(crossAccountRoleArn)
      : null;

    let tasksToStop = await getServiceTasks(
      clusterName,
      serviceName,
      crossAccountCredentials
    );

    let stopTaskPromises = tasksToStop.map((taskToStop) =>
      Promise.resolve(
        stopServiceTask(clusterName, taskToStop, crossAccountCredentials)
      )
    );

    await Promise.all(stopTaskPromises);

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

const getServiceTasks = async (
  clusterName,
  serviceName,
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
    serviceName: serviceName,
  };
  const command = new ListTasksCommand(params);

  try {
    let data = await client.send(command);
    console.log(
      `Successfully got tasks for ${serviceName} service in ${clusterName} cluster`
    );
    return data.taskArns;
  } catch (err) {
    console.error(
      `Error ocurred while getting tasks for ${serviceName} service in ${clusterName} cluster`
    );
    throw err;
  }
};

const stopServiceTask = async (
  clusterName,
  taskArn,
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
    task: taskArn,
  };
  const command = new StopTaskCommand(params);

  try {
    await client.send(command);
    console.log(`Successfully stopped task with ARN ${taskArn}}`);
  } catch (err) {
    console.error(`Error ocurred while stopping task with ARN ${taskArn}`);
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
