{{ define "main-chart.serviceAccount" }}
---
{{- $role := .Values.role_name | default .Values.global.labels.product | replace "-" "_" }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "main-chart.serviceAccountName" . }}-{{ .Values.global.propertiesEnvName }}
  labels:
    {{- include "main-chart.labels" . | nindent 4 }}
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::{{int .Values.global.aws_account_id }}:role/{{ $role }}_role_{{ .Values.global.propertiesEnvName}}
{{- end -}}