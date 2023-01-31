{{ define "main-chart.ingress_alb" }}
---
{{- $fullName := include "main-chart.fullname" . -}}
{{- $svcPort  := .Values.ingress_alb.service_port -}}
{{- $pathType := .Values.ingress_alb.pathType -}}
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "main-chart.fullname" . }}-alb
  labels:
    {{- include "main-chart.labels" . | nindent 4 }}
  {{- with .Values.ingress_alb.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  {{- if .Values.ingress_alb.tls }}
  tls:
    {{- range .Values.ingress_alb.tls }}
    - hosts:
        {{- range .hosts }}
        - {{ . | quote }}
        {{- end }}
      secretName: {{ .secretName }}
    {{- end }}
  {{- end }}
  rules:
    {{- range .Values.ingress_alb.hosts }}
    - host: {{ .host | quote }}
      http:
        paths:
          {{- range .paths }}
          - path: {{ . }}
            pathType: {{ $pathType }}
            backend:
              service:
                name: {{ $fullName }}
                port:
                  number: {{ $svcPort }}
          {{- end }}
    {{- end }}
{{- end -}}
