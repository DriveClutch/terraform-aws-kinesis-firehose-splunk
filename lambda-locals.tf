locals {
  default_lambda_mode = <<EOT
function transformLogEvent(logEvent) {
    return Promise.resolve(`\${logEvent.message}\\n`);
}
EOT

  mysql_to_splunk_lambda_mode = <<EOT
function transformLogEvent(logEvent, data) {
    const { owner, logGroup, logStream } = data;
    var str = logEvent.message;
    // splits incoming string by comma, adds null value for empty fields and removes quotation marks which could be surrounding fields
    var info = str.match(/(?<=,)(?=,)|(?:(?:(?=['"])(?:['"]+([^'"]+)(?:['"]+))))|([^,]+)/g);
    var timestamp = info[0];
    // parse MySQL timestamp which is not compliant to standard datetime formats if match triggers:
    // 20210826 16:32:30
    var time = timestamp.match(/(\d{4})(\d{2})(\d{2})\s*(\d{2}):(\d{2}):(\d{2})/)
    if (time) {
        // month is indexed on 0 and ranges from 0 (January) to 11 (December)
        const timeObj = new Date(time[1], time[2]-1, time[3], time[4], time[5], time[6]);
        // getTime outputs milliseconds but timestamp needs to be in microseconds and formatted as a string to match Splunks newline break RegEx:
        // ([\r\n]+)\{"timestamp":"\d{16}
        timestamp = (timeObj.getTime()*1000).toString();
    }
    const logObj = JSON.stringify({
    timestamp: timestamp,
    serverhost: info[1],
    username: info[2],
    hostname: info[3],
    connectionid: info[4],
    queryid: info[5],
    operation: info[6],
    database: info[7],
    object: info[8],
    retcode: info[9],
    owner,
    logGroup,
    logStream
    });
    // debugging option that outputs the JSON generated for Splunk
    // console.log("JSON\n" + logObj);
    // console.info("JSON\n" + logObj);
    return Promise.resolve(`\${logObj}\\n`);
}
EOT

  postgresql_to_splunk_lambda_mode = <<EOT
function transformLogEvent(logEvent, data) {
    const { owner, logGroup, logStream } = data;
    var str = logEvent.message;
    // splits incoming string by colon. Why: https://aws.amazon.com/blogs/database/working-with-rds-and-aurora-postgresql-logs-part-1/
    var info = str.split(":");

    // re-assemble time stamp and parse it
    var timestamp = [info[0], info[1], info[2]].join(":");
    var timeObj = new Date(Date.parse(timestamp));
    timestamp = (timeObj.getTime()*1000).toString();

    const logObj = JSON.stringify({
    timestamp: timestamp,
    remotehost: info[3],
    username: info[4].split("@")[0],
    dbname: info[4].split("@")[1],
    processid: info[5].replace("[","").replace("]",""),
    message: info[6],
    owner,
    logGroup,
    logStream
    });
    // debugging option that outputs the JSON generated for Splunk
    // console.log("JSON\n" + logObj);
    // console.info("JSON\n" + logObj);
    return Promise.resolve(`\${logObj}\\n`);
}
EOT

  lambda-mode = local.default_lambda_mode
  lambda-mode = var.lambda_function_mode == "custom" ? var.lambda_function_custom_transform_function : local.default_lambda_mode
}