#!/usr/bin/env sh
set -eu

source $(dirname $(realpath $0))/variables.sh

if [ ! -d "$LAYERS_DIR" ]; then
  # don't apply anything if there's no layers directory, we're likely in the
  # common repo here, and shouldn't be running Terraform at all.
  echo "> Not applying, no layers directory were found."
  exit
fi

if [ -z "$CHANGED_LAYERS" ]; then
  echo "> No changed layers to apply."
  exit
fi

for LAYER in $CHANGED_LAYERS; do
  echo "> Applying layer: $LAYER"
  # for debugging, show that these files exist
  ls -la "$WORKSPACE_DIR/.terraform.$LAYER.tar.gz"
  ls -la "$WORKSPACE_DIR/terraform.$LAYER.plan"

  # uncache .terraform for the apply
  (cd "$LAYERS_DIR/$LAYER" && tar xzf "$WORKSPACE_DIR/.terraform.$LAYER.tar.gz")

  APPLY_COMMAND="terraform apply -input=false -no-color "$WORKSPACE_DIR/terraform.$LAYER.plan""
  echo "$ $APPLY_COMMAND"
  (cd "$LAYERS_DIR/$LAYER" && $APPLY_COMMAND)
done

# escrows applied revision
REVISION="${CIRCLE_SHA1:-$(git rev-parse HEAD)}"
echo "$REVISION" > tf-applied-revision.sha
aws s3 cp ./tf-applied-revision.sha "s3://${TF_STATE_BUCKET}/"
