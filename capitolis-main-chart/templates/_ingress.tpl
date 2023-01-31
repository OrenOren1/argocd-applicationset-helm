{{ define "main-chart.ingress" }}
---
{{- $fullName := include "main-chart.fullname" . -}}
{{- $svcPort  := .Values.ingress.service_port | default 80 -}}
{{- $pathType := .Values.ingress.pathType | default "Prefix" -}}
{{- $backendHost := .Values.ingress.backend_host -}}
{{- $propertiesEnvName := required "propertiesEnvName is required" .Values.global.propertiesEnvName }}

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "main-chart.fullname" . }}
  labels:
    {{- include "main-chart.labels" . | nindent 4 }}
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    external-dns.alpha.kubernetes.io/hostname: ""
    {{- if  .Values.ingress.annotations  }}
    {{- with .Values.ingress.annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
    {{- end }}
spec:
  {{- if  .Values.ingress.tls  }}
  tls:
  {{- range .Values.ingress.tls }}
  - hosts:
      {{- range .hosts }}
      - {{ . | quote }}
      {{- end }}
    secretName: {{ .secretName }}
  {{- end -}}
  {{- end }}
  rules:
    {{- range .Values.ingress.hosts  }}
    - host: {{$fullName}}.{{$propertiesEnvName}}-ingress.tikal.is
      http:
        paths:
          {{- range .paths }}
          - path: /
            pathType: {{ $pathType }}
            backend:
              service:
              {{- if $backendHost }}
                name: {{ $backendHost }}
              {{- else }}
                name: {{ $fullName }}
              {{- end }}
                port:
                  number: {{ $svcPort }}
          {{- end }}
      {{- end }}
{{- end -}}
