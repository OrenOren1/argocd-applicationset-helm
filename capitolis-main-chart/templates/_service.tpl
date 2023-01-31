{{ define "main-chart.service" }}
---
{{- if .Values.deployment.enabled  -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "main-chart.fullname" . }}
  labels:
    {{- include "main-chart.labels" . | nindent 4 }}
spec:
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 8082
  {{- if .Values.service  }}
  {{- range $value := .Values.service.ports }}
    - name: {{ $value.name }}
      protocol: {{ $value.protocol }}
      port: {{ $value.port }}
      targetPort: {{ $value.targetPort }}
  {{- end }}
  {{- end }}
  selector:
    {{- include "main-chart.selectorLabels" . | nindent 4 }}
  sessionAffinity: {{ .Values.service.sessionAffinity | default "None" }}
  type: {{ .Values.service.type | default "ClusterIP" }}
{{- end -}}
{{- end -}}