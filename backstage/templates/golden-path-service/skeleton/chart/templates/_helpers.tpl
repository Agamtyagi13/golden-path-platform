{{- define "svc.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "svc.selectorLabels" -}}
app.kubernetes.io/name: {{ include "svc.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "svc.labels" -}}
{{ include "svc.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Values.system | quote }}
owner: {{ .Values.owner | quote }}
environment: {{ .Values.environment | quote }}
backstage.io/kubernetes-id: {{ include "svc.name" . }}
{{- end }}
