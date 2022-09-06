/**
 * Triggered from a message on a Cloud Pub/Sub topic.
 *
 * @param {!Object} message Event payload.
 * @param {!Object} context Metadata for the event.
 * @author Anjali Khatri & Nitin Vashishtha
 */
 exports.cloudDeployApproval = (message, context) => {

    const attributes = message.attributes
    action = attributes.Action;
  
    if (action == 'Required') { // you can implement your own logic for other two events 'Approved' and 'Rejected' as per your requirements
    const sendgrid = require('@sendgrid/mail');
    sendgrid.setApiKey(process.env.SENDGRID_API_KEY);
    rollout = attributes.Rollout
    const rolloutSplit = rollout.split("/");
    pipeline = rolloutSplit[5];
    const location = attributes.Location;
    const releaseid = rolloutSplit[7];
    const projectnbr = attributes.ProjectNumber;
  
    const slash = "/";
    const consoleurl = 'https://console.cloud.google.com/deploy/delivery-pipelines';
    var deployurl = consoleurl + slash + location + slash + pipeline + '/releases' + slash + releaseid + slash + 'rollouts?ProjectID=' + projectnbr;
    console.log("Cloud deploy URL :"+ deployurl);
    // you can also insert your test suite/ results link in the email for review/verification 
    const msg = {
      to: process.env.TO_EMAIL,
      from: process.env.FROM_EMAIL,
      subject: 'Approval Needed: Google Cloud Deploy Rollout',
      html: 'Hello! A Google Cloud Deploy rollout for pipeline <b>"' + pipeline + '" </b> needs your attention. To approve or reject the rollout click <a href=' + deployurl + '>here.</a>',
  }
  try {
  sendgrid.send(msg);
  console.log("Email sent successfully");
  }catch (e) {
    console.log("Error sending email:"+ e);
  }
    }
  
  };