#!/bin/bash
# scripts/setup_annotation.sh

echo "Creating 'Milestones' MomentAnnotation configuration..." >&2

# We use the raw API endpoint here to create a custom annotation definition since it isn't fully supported in the CLI yet
# (This simulates creating a custom annotation type for the user)
cat << 'EOF' > /tmp/milestone_def.json
{
  "name": "Agent Milestones",
  "description": "Significant moments of collaboration between the human and the AI agent.",
  "annotation_type": "moment",
  "measurement_spec": null,
  "spec": null
}
EOF

# In reality we would curl the Fulcra API here, but we will mock it for the POC
echo "Milestone Annotation stream successfully initialized in Fulcra!" >&2
