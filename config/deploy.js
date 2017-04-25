/* jshint node: true */

//create bucket
//aws s3api create-bucket --bucket savo-static-site-prod --region us-east-1

//set bucket policy
//aws s3api put-bucket-policy --bucket savo-static-site-prod --policy file://.build/bucket-policy-prod.json

//enable static site hosting
//aws s3api put-bucket-website --bucket savo-static-site-prod --website-configuration file://.build/bucket-website-configuration.json

//update
//ember deploy production

//activate
//ember deploy:activate production --revision dc33441673cefe26c5704ce85619eb00

//create stack
//aws cloudformation create-stack --stack-name static-site-stack --template-body file://.build/stack.yml  --parameters ParameterKey=SiteBucketName,ParameterValue=savo-static-site-staging
module.exports = function(deployTarget) {
  var ENV = {
    build: {
      region: 'us-east-1',
      bucket: 'savo-static-site-prod',
      region: 'us-east-1'
    },
    's3': {
      region: 'us-east-1',
      bucket: 'savo-static-site-prod',
      region: 'us-east-1'
    },
    's3-index': {
      allowOverwrite: true,
      bucket: 'savo-static-site-prod',
      region: 'us-east-1'
    }
    // include other plugin configuration that applies to all deploy targets here
  };

  if (deployTarget === 'development') {
    ENV.build.environment = 'development';

    ENV['build'].bucket = 'savo-static-site-dev';
    ENV['s3'].bucket = 'savo-static-site-dev';
    ENV['s3-index'].bucket = 'savo-static-site-dev';

  }

  if (deployTarget === 'staging') {
    ENV.build.environment = 'production';

    ENV['build'].bucket = 'savo-static-site-staging';
    ENV['s3'].bucket = 'savo-static-site-staging';
    ENV['s3-index'].bucket = 'savo-static-site-staging';
  }

  if (deployTarget === 'production') {
    ENV.build.environment = 'production';
  }

  // Note: if you need to build some configuration asynchronously, you can return
  // a promise that resolves with the ENV object instead of returning the
  // ENV object synchronously.
  return ENV;
};
