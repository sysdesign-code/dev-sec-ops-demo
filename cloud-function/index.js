/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} message Event payload.
 * @param {!Object} context Metadata for the event.
 */
 exports.cloudDeployApproval = (message, context) => {

    const attributes = message.attributes
    action = attributes.Action;
    console.log("action: "+action);
  
    if (action == 'Required') {
    const sendgrid = require('@sendgrid/mail');
    sendgrid.setApiKey(process.env.SENDGRID_API_KEY);
    rollout = attributes.Rollout
    console.log("Rollout: " + rollout);
    var rolloutSplit = rollout.split("/");
    pipeline = rolloutSplit[5];
    var location = attributes.Location;
    var releaseid = attributes.ReleaseID;
    releaseid = rolloutSplit[7];
    console.log("release id:" + releaseid);
    var rolloutid = attributes.RolloutID;
    console.log("rollout id:" + rolloutid);
    var targetid = attributes.TargetID;
    console.log("taregt id:" + targetid);
    var projectnbr = attributes.ProjectNumber;
    console.log("projectnbr:" + projectnbr);
    var pipelineid = attributes.PipelineID;
    console.log("PipelineID:" + pipelineid);
  
    var slash = "/";
    var consoleurl = 'https://console.cloud.google.com/deploy/delivery-pipelines';
    var deployurl = consoleurl + slash + location + slash + pipeline + '/releases' + slash + releaseid + slash + 'rollouts?ProjectID=' + projectnbr;
    console.log("Cloud deploy URL :"+ deployurl);
    // you can also insert your test suite/ results link in the email for review/verification 
    const msg = {
      to: process.env.TO_EMAIL,
      from: process.env.FROM_EMAIL,
      subject: 'Approval Needed: Google Cloud Deploy Build',
      html: 'Hello! A Google Cloud Deploy release needs your attention. To approve or reject the release click <a href=' + deployurl + '>here.</a>',
  }
  sendgrid.send(msg);
    }
  
  };