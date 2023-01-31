{{ define "main-chart.deployment" }}
---
{{- if .Values.deployment.enabled  -}}
{{- $env_vars := .Values.env }}
{{- $service_name := include "main-chart.fullname" . }}
{{- $tag := required "image.tag is required" .Values.image.tag }}
{{- $propertiesEnvName := required "propertiesEnvName is required" .Values.global.propertiesEnvName }}
{{- $product :=  .Values.global.labels.product }}
{{- $team :=  .Values.global.labels.team }}
{{- $role := .Values.role_name | default .Values.global.labels.product | replace "-" "_" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "main-chart.fullname" . }}
  labels:
    {{- include "main-chart.labels" . | nindent 4 }}
    app: {{ include "main-chart.fullname" . }}
    project: tikal
    team: {{ $team }}
    product: {{ $product }}
{{- if .Values.labels }}
{{ toYaml .Values.labels | indent 4 }}
{{- end }}
spec:
  revisionHistoryLimit: {{ .Values.revisionHistoryLimit | default 0 }}
  {{- if .Values.strategy }}
  strategy:
{{ toYaml .Values.strategy | indent 6 }}
  {{- end }}
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount | default 1 }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "main-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        iam.amazonaws.com/role: arn:aws:iam::{{int .Values.global.aws_account_id }}:role/{{ $role }}_role_{{ .Values.global.propertiesEnvName}}
        checksum/config: {{ include (print $.Template.BasePath "/cm.yaml") . | sha256sum }}
      {{- with .Values.podAnnotations }}
        {{- toYaml . | nindent 8 }}
      {{- end }}
      labels:
        {{- include "main-chart.selectorLabels" . | nindent 8 }}
        app: {{ include "main-chart.fullname" . }}
        project: tikal
        team: {{ $team }}
        {{- if .Values.SpotinstRestrictScaleDown }}
        spotinst.io/restrict-scale-down: "true"
        {{- end }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      serviceAccountName: {{ include "main-chart.serviceAccountName" . }}-{{ .Values.global.propertiesEnvName }}
      securityContext:
        {{- toYaml .Values.podSecurityContext | nindent 8 }}
      containers:
        - name: {{ include "main-chart.fullname" . }}
          securityContext:
            {{- toYaml .Values.securityContext | nindent 12 }}
          image: "607827849963.dkr.ecr.eu-west-1.amazonaws.com/cptls/{{ $service_name }}:{{ $tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy | default "Always" | quote }}
        {{- if .Values.containerCommand }}
          command:
            {{ toYaml .Values.containerCommand | nindent 12 }}
        {{- end }}
          livenessProbe:
            failureThreshold: 3
            httpGet:
              path: {{ .Values.livenessProbe.httpGet.path | default "/health" | quote }}
              port: {{ .Values.livenessProbe.httpGet.port | default 8082 }}
              scheme: {{ .Values.livenessProbe.httpGet.scheme | default "HTTP" | quote }}
            initialDelaySeconds: 300
            periodSeconds: 30
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path:  {{ .Values.readinessProbe.httpGet.path | default "/health" | quote }}
              port: {{ .Values.readinessProbe.httpGet.port | default 8082 }}
              scheme: {{ .Values.readinessProbe.httpGet.scheme | default "HTTP" | quote }}
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          resources:
            limits:
              cpu: {{ ((.Values.resources).limits).cpu | default "500m" | quote }}
              memory: {{ ((.Values.resources).limits).memory | default "1.5Gi" | quote }}
            requests:
              cpu: {{ ((.Values.resources).requests).cpu | default "200m" | quote }}
              memory: {{ ((.Values.resources).requests).memory | default "1Gi" | quote }}
          env:
            {{- range $name, $value := .Values.global.env }}
            {{- if not (empty $value) }}
            - name: {{ $name | quote }}
              value: {{ $value | quote }}
            {{- end }}
            {{- end }}
            {{- range $name, $value := $env_vars }}
            {{- if not (empty $value) }}
            - name: {{ $name | quote }}
              value: {{ $value | quote }}
            {{- end }}
            {{- end }}
            {{- range $name, $value := .Values.extraEnvVars }}
            {{- if not (empty $value) }}
            - name: {{ $name | quote }}
              value: {{ $value | quote }}
            {{- end }}
            {{- end }}
            - name: "SERVICE_NAME"
              value: {{ $service_name | quote }}
          envFrom:
            - secretRef:
                name: tikal-secrets
          volumeMounts:
            - mountPath: {{ .Values.externalsecrets_path | default "/usr/src/app/config/application-kamus.properties" | quote}}
              name: tikal-secrets
              subPath: application-kamus.properties
            {{- if .Values.configmap.log4j_mount.enabled  }}
            - mountPath: /usr/src/app/config/application-json_layout.properties
              name: config-log4j-properties
              subPath: application-json_layout.properties

            - mountPath: /usr/src/app/config/log4j2-json_layout.json
              name: config-log4j
              subPath: log4j2-json_layout.json
            {{- end }}
            {{- if .Values.configmap.load_default_application_properties }}
            - mountPath: /usr/src/app/config/application-{{ $propertiesEnvName }}.properties
              name: config
              subPath: application-{{ $propertiesEnvName }}.properties
            {{- end }}
            {{- if .Values.configmap.custom.extraVolumeMounts }}
{{ tpl (toYaml .Values.configmap.custom.extraVolumeMounts) $ | indent 12 }}
            {{- end }}
              {{- range $volumeMount := .Values.extraVolumeMounts }}
                - name: {{ $volumeMount.name }}
                  mountPath: {{ $volumeMount.mountPath }}
                  {{ if $volumeMount.subPath }}
                  subPath: {{ $volumeMount.subPath }}
                  {{- end }}
                  {{ if $volumeMount.readOnly }}
                  readOnly: {{ $volumeMount.readOnly }}
                  {{- end }}
          {{- end }}
      {{- if .Values.nodeSelector }}
      nodeSelector:
      {{ toYaml .Values.nodeSelector | indent 8 }}
      {{- end }}
      volumes:
        - name: tikal-secrets
          secret:
            defaultMode: 420
            secretName: tikal-secrets
        {{- if .Values.configmap.log4j_mount.enabled }}
        - configMap:
            items:
              - key: application-json_layout.properties
                path: application-json_layout.properties
            name: {{ $product }}-properties
          name: config-log4j-properties
        - configMap:
            items:
              - key: log4j2-json_layout.json
                path: log4j2-json_layout.json
            name: {{ $product }}-properties
          name: config-log4j
      {{- end }}
      {{- if .Values.configmap.load_default_application_properties }}
        - configMap:
            items:
            - key: application-env.properties
              path: application-{{ $propertiesEnvName }}.properties
            name: {{ $product }}-properties
          name: config
      {{- end }}
      {{- if .Values.configmap.custom  }}
{{ tpl (toYaml .Values.configmap.custom.extraVolumesProperties) $ | indent 8 }}
      {{- end }}
{{- end -}}
{{- end -}}