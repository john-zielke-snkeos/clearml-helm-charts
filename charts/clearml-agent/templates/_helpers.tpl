{{/*
Expand the name of the chart.
*/}}
{{- define "clearml.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "clearml.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "clearml.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "clearml.labels" -}}
helm.sh/chart: {{ include "clearml.chart" . }}
{{ include "clearml.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "clearml.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearml.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Reference Name (agentk8sglue)
*/}}
{{- define "agentk8sglue.referenceName" -}}
{{- include "clearml.fullname" . }}-agentk8sglue
{{- end }}

{{/*
Selector labels (agentk8sglue)
*/}}
{{- define "agentk8sglue.selectorLabels" -}}
app.kubernetes.io/name: {{ include "clearml.name" . }}
app.kubernetes.io/instance: {{ include "agentk8sglue.referenceName" . }}
{{- end }}

{{/*
Worker namespace (agentk8sglue)
*/}}
{{- define "agentk8sglue.defaultNamespace" -}}
{{- default .Release.Namespace .Values.agentk8sglue.defaultNamespace }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agentk8sglue.serviceAccountName" -}}
{{/* Does not support creation

{{- if .Values.serviceAccount.create }}
{{- default (include "clearml.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
*/}}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "agentk8sglue.jobServiceAccountName" -}}
{{/* Does not support creation
{{- if .Values.agentk8sglue.serviceAccount.create }}
{{- default (include "clearml.fullname" .) .Values.agentk8sglue.serviceAccount.name }}
{{- else }}
{{- .Values.agentk8sglue.serviceAccount.name | default .Values.serviceAccount.name | default "default" }}
{{- end }}
*/}}
{{- .Values.agentk8sglue.serviceAccount.name | default .Values.serviceAccount.name | default "default" }}
{{- end }}

{{/*
Create secret to access docker registry
*/}}
{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{- define "agentk8sglue.volumes" -}}
{{- if .Values.extraVolumes }}
{{ toYaml .Values.extraVolumes }}
{{- end }}
- name: {{ include "agentk8sglue.referenceName" . }}-k8sagent-pod-template
  configMap: 
    name: {{ include "agentk8sglue.referenceName" . }}-k8sagent-pod-template
{{- if or .Values.clearml.clearmlConfig .Values.clearml.existingClearmlConfigSecret }}
- name: k8sagent-clearml-conf-volume
  secret:
    {{- if .Values.clearml.existingClearmlConfigSecret }}
    secretName: {{ .Values.clearml.existingClearmlConfigSecret }}
    {{- else }}
    secretName: {{ include "agentk8sglue.referenceName" . }}-clearml-agent-conf
    {{- end }}
    items:
    - key: clearml.conf
      path: clearml.conf
{{ end }}
{{- end }}