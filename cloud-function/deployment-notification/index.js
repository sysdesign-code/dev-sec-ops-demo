/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} message Event payload.
 * @param {!Object} context Metadata for the event.
 * @author Anjali Khatri & Nitin Vashishtha
 */
 exports.cloudDeployStatus = (message, context) => {

    const attributes = message.attributes
    action = attributes.Action;
  
    if (action == 'Failure') { // you can implement your own logic for other two events 'Start' and 'Succeed' as per your requirements
    const sendgrid = require('@sendgrid/mail');
    sendgrid.setApiKey(process.env.SENDGRID_API_KEY);
    resource = attributes.Resource
    console.log("resource: "+resource);
    const resourceSplit = resource.split("/");
    pipeline = resourceSplit[5];
    const location = attributes.Location;
    const releaseid = resourceSplit[7];
    const projectnbr = attributes.ProjectNumber;
  
    const slash = "/";
    const consoleurl = 'https://console.cloud.google.com/deploy/delivery-pipelines';
    var deployurl = consoleurl + slash + location + slash + pipeline + '/releases' + slash + releaseid + slash + 'rollouts?ProjectID=' + projectnbr;
    console.log("Cloud deploy URL :"+ deployurl);
    // you can also insert your test suite/ results link in the email for review/verification 
    const msg = {
      to: process.env.TO_EMAIL,
      from: process.env.FROM_EMAIL,
      subject: 'Google Cloud Deploy Rollout Failed',
      html: 'Hello! A Google Cloud Deploy rollout for pipeline <b>"' + pipeline + '" </b> is failed to deploy. Click <a href=' + deployurl + '>here to see deployment logs</a>',
  }
  try {
  sendgrid.send(msg);
  console.log("Email sent successfully");
  }catch (e) {
    console.log("Error sending email:"+ e);
  }
    }
  
  };