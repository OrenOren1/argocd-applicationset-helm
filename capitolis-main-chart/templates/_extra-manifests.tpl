{{ define "main-chart.extraObjects" }}
{{ range .Values.extraObjects }}
---
{{ tpl (toYaml .) $ }}
{{ end }}
{{ end }}
