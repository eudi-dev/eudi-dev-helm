{{/*
Copyright Dominik Schlosser
SPDX-License-Identifier: APACHE-2.0
*/}}

{{/* vim: set filetype=mustache: */}}

{{/*
Return the proper eudi-dev image name
*/}}
{{- define "eudi-dev.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global) }}
{{- end -}}

{{/*
Return the proper Docker Image Registry Secret Names
*/}}
{{- define "eudi-dev.imagePullSecrets" -}}
{{ include "common.images.renderPullSecrets" (dict "images" (list .Values.image) "context" $) }}
{{- end -}}

{{/*
Return the name of the service account to use
*/}}
{{- define "eudi-dev.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "common.names.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Return the public URL of the wallet. Without baseURL it is the ingress URL, or the
in-cluster service URL when the ingress is disabled.
*/}}
{{- define "eudi-dev.baseURL" -}}
{{- if .Values.baseURL -}}
    {{- tpl .Values.baseURL . | trimSuffix "/" -}}
{{- else if .Values.ingress.enabled -}}
    {{- printf "%s://%s%s" (ternary "https" "http" .Values.ingress.tls) (tpl .Values.ingress.hostname .) (trimSuffix "/" .Values.ingress.path) -}}
{{- else -}}
    {{- printf "http://%s.%s.svc.%s:%v" (include "common.names.fullname" .) (include "common.names.namespace" .) .Values.clusterDomain .Values.service.ports.http -}}
{{- end -}}
{{- end -}}

{{/*
Return the path of the public URL without a trailing slash, such as /some/context, or
an empty string when the wallet runs at the root of its host.
*/}}
{{- define "eudi-dev.basePath" -}}
{{- (urlParse (include "eudi-dev.baseURL" .)).path | trimSuffix "/" -}}
{{- end -}}

{{/*
Return the path the ingress or HTTPRoute routes to the wallet
*/}}
{{- define "eudi-dev.routePath" -}}
{{- if .Values.ingress.path -}}
    {{- .Values.ingress.path -}}
{{- else -}}
    {{- default "/" (include "eudi-dev.basePath" .) -}}
{{- end -}}
{{- end -}}

{{/*
Return the issuer metadata paths at the host root, one per line. The specs insert the
well-known name before the issuer path (RFC 8414 §3.1, OpenID4VCI 1.0 §12.2.2), so these
paths are outside the wallet's base path.
*/}}
{{- define "eudi-dev.wellKnownPaths" -}}
{{- $basePath := include "eudi-dev.basePath" . -}}
{{- if $basePath -}}
{{- range list "openid-credential-issuer" "oauth-authorization-server" "jwt-vc-issuer" }}
{{ printf "/.well-known/%s%s" . $basePath }}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the secret with the seed and the database password
*/}}
{{- define "eudi-dev.secretName" -}}
{{- include "common.names.fullname" . -}}
{{- end -}}

{{/*
Return the name of the secret with the seed
*/}}
{{- define "eudi-dev.seedSecretName" -}}
{{- default (include "eudi-dev.secretName" .) (tpl .Values.seed.existingSecret .) -}}
{{- end -}}

{{/*
Return the key of the seed in its secret
*/}}
{{- define "eudi-dev.seedSecretKey" -}}
{{- ternary .Values.seed.existingSecretKey "seed" (not (empty .Values.seed.existingSecret)) -}}
{{- end -}}

{{/*
Return the name of the secret with the database password, or an empty string when
there is no password
*/}}
{{- define "eudi-dev.databaseSecretName" -}}
{{- if .Values.externalDatabase.existingSecret -}}
    {{- tpl .Values.externalDatabase.existingSecret . -}}
{{- else if .Values.externalDatabase.password -}}
    {{- include "eudi-dev.secretName" . -}}
{{- end -}}
{{- end -}}

{{/*
Return the key of the database password in its secret
*/}}
{{- define "eudi-dev.databaseSecretKey" -}}
{{- ternary .Values.externalDatabase.existingSecretPasswordKey "database-password" (not (empty .Values.externalDatabase.existingSecret)) -}}
{{- end -}}

{{/*
Return the value of EUDI_DEV_STORAGE. The database password comes from PGPASSWORD, so
it never needs URL escaping.
*/}}
{{- define "eudi-dev.storage" -}}
{{- if eq .Values.storage.type "postgresql" -}}
    {{- $db := .Values.externalDatabase -}}
    {{- printf "postgres://%s@%s:%v/%s?sslmode=%s" (urlquery $db.user) (tpl $db.host .) $db.port (urlquery $db.database) $db.sslMode -}}
{{- else -}}
    {{- .Values.storage.type -}}
{{- end -}}
{{- end -}}

{{/*
Return issuance.vciVersion as a string. YAML reads an unquoted 1.0 as a number.
*/}}
{{- define "eudi-dev.vciVersion" -}}
{{- $version := .Values.issuance.vciVersion -}}
{{- if kindIs "float64" $version -}}
    {{- printf "%.1f" $version -}}
{{- else -}}
    {{- toString $version -}}
{{- end -}}
{{- end -}}

{{/*
Return the name of the ConfigMap the chart creates for the imprint, the demo verifier
issuer CAs, the relying party CAs, the credential templates and the startup credentials
*/}}
{{- define "eudi-dev.configMapName" -}}
{{- printf "%s-files" (include "common.names.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return true when the chart creates its ConfigMap
*/}}
{{- define "eudi-dev.createConfigMap" -}}
{{- if or (and .Values.imprint.html (not .Values.imprint.existingConfigMap)) (and .Values.demoVerifier.issuerCAs (not .Values.demoVerifier.existingIssuerCASecret)) (and .Values.relyingPartyCAs (not .Values.existingRelyingPartyCASecret)) (and .Values.credentialTemplates.templates (not .Values.credentialTemplates.existingConfigMap)) (and .Values.credentials.items (not .Values.credentials.existingConfigMap)) (and .Values.catalog.entries (not .Values.catalog.existingConfigMap)) (and .Values.relyingParties.registrations (not .Values.relyingParties.existingConfigMap)) (include "eudi-dev.pidCredentialsEnabled" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the file name of a credential template in the ConfigMap
*/}}
{{- define "eudi-dev.templateFileName" -}}
{{- if or (hasSuffix ".json" .) (hasSuffix ".template" .) -}}
    {{- . -}}
{{- else -}}
    {{- printf "%s.json" . -}}
{{- end -}}
{{- end -}}

{{/*
Return true when the wallet adds startup credentials
*/}}
{{- define "eudi-dev.startupCredentials" -}}
{{- if or .Values.credentials.items .Values.credentials.existingConfigMap (include "eudi-dev.pidCredentialsEnabled" .) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return true when the wallet issues pidCredentials. The public demo brings its own PIDs, which every reset restores.
*/}}
{{- define "eudi-dev.pidCredentialsEnabled" -}}
{{- if and .Values.pidCredentials (not .Values.demo.enabled) -}}
    {{- true -}}
{{- end -}}
{{- end -}}

{{/*
Return the startup credentials file for pidCredentials: one SD-JWT VC and one mdoc per PID template
*/}}
{{- define "eudi-dev.pidCredentials" -}}
{{- $items := list -}}
{{- range $pid := .Values.pidCredentials -}}
{{- range $format := list "sdjwt" "mdoc" -}}
{{- $name := printf "%s-%s" $pid $format -}}
{{- $items = append $items (dict "id" $name "template" $name) -}}
{{- end -}}
{{- end -}}
{{- dict "credentials" $items | toYaml -}}
{{- end -}}

{{/*
Return the value of NO_PROXY. In-cluster services never go through the proxy, so a
wallet with an in-cluster base URL still reaches its own demo issuer and verifier.
*/}}
{{- define "eudi-dev.noProxy" -}}
{{- $hosts := without (splitList "," .Values.outboundProxy.noProxy) "" -}}
{{- join "," (concat $hosts (list ".svc" (printf ".%s" .Values.clusterDomain))) -}}
{{- end -}}

{{/*
Return the ports of the configured proxies, one per line. A proxy URL without a
scheme uses http, as eudi-dev does.
*/}}
{{- define "eudi-dev.proxyPorts" -}}
{{- $defaults := dict "http" "80" "https" "443" "socks5" "1080" "socks5h" "1080" -}}
{{- $ports := list -}}
{{- range list .Values.outboundProxy.httpsProxy .Values.outboundProxy.httpProxy -}}
{{- if . -}}
{{- $url := urlParse (ternary . (printf "http://%s" .) (contains "://" .)) -}}
{{- $port := regexFind "[0-9]+$" (regexFind ":[0-9]+$" $url.host) -}}
{{- $ports = append $ports (default (get $defaults $url.scheme) $port) -}}
{{- end -}}
{{- end -}}
{{- join "\n" (uniq $ports) -}}
{{- end -}}

{{/*
Collect the validation errors into one message and fail on them
*/}}
{{- define "eudi-dev.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.storage" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.replicaCount" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.validationMode" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.logFormat" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.options" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.httpRoute" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.ports" .) -}}
{{- $messages := append $messages (include "eudi-dev.validateValues.renamed" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}
{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message | fail -}}
{{- end -}}
{{- end -}}

{{- define "eudi-dev.validateValues.storage" -}}
{{- if not (has .Values.storage.type (list "memory" "file" "postgresql")) -}}
eudi-dev: storage.type
    Invalid storage type "{{ .Values.storage.type }}". Use memory, file or postgresql.
{{- else if and (eq .Values.storage.type "postgresql") (not .Values.externalDatabase.host) -}}
eudi-dev: externalDatabase.host
    storage.type=postgresql needs the database host in externalDatabase.host.
{{- end -}}
{{- end -}}

{{- define "eudi-dev.validateValues.replicaCount" -}}
{{- if and (gt (int .Values.replicaCount) 1) (ne .Values.storage.type "postgresql") -}}
eudi-dev: replicaCount
    More than one replica needs storage.type=postgresql. With memory or file storage each pod would be a separate wallet.
{{- end -}}
{{- end -}}

{{- define "eudi-dev.validateValues.validationMode" -}}
{{- if not (has .Values.validationMode (list "debug" "strict")) -}}
eudi-dev: validationMode
    Invalid validation mode "{{ .Values.validationMode }}". Use debug or strict.
{{- end -}}
{{- end -}}

{{- define "eudi-dev.validateValues.logFormat" -}}
{{- if not (has .Values.logFormat (list "text" "json")) -}}
eudi-dev: logFormat
    Invalid log format "{{ .Values.logFormat }}". Use text or json.
{{- end -}}
{{- end -}}

{{/*
Validate the values that eudi-dev accepts from a fixed list
*/}}
{{- define "eudi-dev.validateValues.options" -}}
{{- $options := list
    (dict "name" "haip" "value" (toString .Values.haip) "allowed" (list "" "true" "false"))
    (dict "name" "arf" "value" (toString .Values.arf) "allowed" (list "" "true" "false"))
    (dict "name" "issuance.vciVersion" "value" (include "eudi-dev.vciVersion" .) "allowed" (list "" "1.0" "1.1"))
    (dict "name" "issuance.keyAttestationLevel" "value" .Values.issuance.keyAttestationLevel "allowed" (list "" "none" "iso_18045_high" "iso_18045_moderate" "iso_18045_enhanced-basic" "iso_18045_basic"))
    (dict "name" "presentation.sessionTranscript" "value" .Values.presentation.sessionTranscript "allowed" (list "" "oid4vp" "iso"))
    (dict "name" "presentation.preferredFormat" "value" .Values.presentation.preferredFormat "allowed" (list "" "dc+sd-jwt" "mso_mdoc" "jwt_vc_json"))
    (dict "name" "demoIssuer.clientAuth" "value" .Values.demoIssuer.clientAuth "allowed" (list "" "required" "optional"))
-}}
{{- $messages := list -}}
{{- range $options -}}
{{- if not (has .value .allowed) -}}
{{- $messages = append $messages (printf "eudi-dev: %s\n    Invalid value \"%s\". Use %s, or leave it empty." .name .value (join ", " (without .allowed ""))) -}}
{{- end -}}
{{- end -}}
{{- join "\n" $messages -}}
{{- end -}}


{{/*
Validate the HTTPRoute. The wallet cannot read the Gateway's public URL.
*/}}
{{- define "eudi-dev.validateValues.httpRoute" -}}
{{- if .Values.httpRoute.enabled -}}
{{- if not .Values.baseURL -}}
eudi-dev: baseURL
    httpRoute.enabled needs the public URL of the Gateway in baseURL.
{{- else if not .Values.httpRoute.parentRefs -}}
eudi-dev: httpRoute.parentRefs
    httpRoute.enabled needs the Gateways in httpRoute.parentRefs.
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate the service ports. Without baseURL and ingress the wallet advertises its
in-cluster service URL with the container ports, and its issuer on the next port.
*/}}
{{- define "eudi-dev.validateValues.ports" -}}
{{- if and (not .Values.baseURL) (not .Values.ingress.enabled) -}}
{{- if or (ne (int .Values.service.ports.http) (int .Values.containerPorts.http)) (ne (int .Values.service.ports.issuer) (add1 (int .Values.containerPorts.http))) -}}
eudi-dev: service.ports
    Without baseURL the wallet advertises {{ .Values.containerPorts.http }} and {{ add1 (int .Values.containerPorts.http) }}. Set service.ports.http and service.ports.issuer to these ports, or set baseURL.
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Validate that no value renamed in 1.0.0 is set, since the chart reads only the new names.
*/}}
{{- define "eudi-dev.validateValues.renamed" -}}
{{- $renamed := list -}}
{{- if .Values.importCredentials -}}
{{- $renamed = append $renamed "use credentials instead of importCredentials" -}}
{{- end -}}
{{- if .Values.demoVerifier.trustAnchors -}}
{{- $renamed = append $renamed "use demoVerifier.issuerCAs instead of demoVerifier.trustAnchors" -}}
{{- end -}}
{{- if hasKey .Values "generatePID" -}}
{{- $renamed = append $renamed "use pidCredentials instead of generatePID" -}}
{{- end -}}
{{- if .Values.demoVerifier.existingTrustAnchorsSecret -}}
{{- $renamed = append $renamed "use demoVerifier.existingIssuerCASecret instead of demoVerifier.existingTrustAnchorsSecret" -}}
{{- end -}}
{{- if $renamed -}}
eudi-dev: renamed values
    {{ join ". " $renamed }}. See "Upgrading to 1.0.0" in the README.
{{- end -}}
{{- end -}}
