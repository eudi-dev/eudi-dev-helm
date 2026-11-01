# Changelog

Notable changes by chart version. The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [3.6.0] - 2026-11-01

### Added

- `arf` turns on the ARF checks of verifiers and issuers, and `relyingPartyCAs` adds the CAs of other registrars
- Artifact Hub metadata: links, license, category, images and changes
- The service ports carry `appProtocol`, so a service mesh detects HTTP on `http` and TLS on `issuer`
- `catalog` pre-registers attestation types and `relyingParties` registers verifiers and issuers on every start, inline or from an existing ConfigMap

### Changed

- The chart version follows the major and minor version of eudi-dev, so chart 3.6.x deploys eudi-dev 3.6.x. It skips the versions between 0.2.0 and 3.6.0
- `pidCredentials` alone decides which PIDs the wallet holds. The image no longer adds a second EUDI PID
- `autoAccept: false` now wins over the default of the image
- Deploys eudi-dev 3.6.1 from `ghcr.io/eudi-dev/eudi-dev`
- `credentials` replaces `importCredentials` and issues or imports credentials on every start
- `pidCredentials` replaces `generatePID`. By default the wallet holds the EUDI, German, Italian and Dutch PIDs, each as SD-JWT VC and mdoc
- The chart fails when `httpRoute.enabled` is set without `baseURL` or `httpRoute.parentRefs`
- The chart fails when neither `baseURL` nor the ingress is set and the service ports differ from the container ports
- `podSecurityContext.fsGroupChangePolicy` defaults to `OnRootMismatch`
- `demoVerifier.issuerCAs` and `demoVerifier.existingIssuerCASecret` replace `demoVerifier.trustAnchors` and `demoVerifier.existingTrustAnchorsSecret`
- The chart fails on the renamed values (see [Upgrading to 1.0.0](README.md#to-100))

## [0.2.0] - 2026-10-04

### Added

- `logFormat=json` writes JSON log records (`EUDI_DEV_LOG_FORMAT`)
- Values for every `wallet serve` flag that applies in Kubernetes: `haip`, `statusList`, `adhocDisplayImages`, `issuance.*`, `presentation.*`, `demoIssuer.clientAuth`, `demoVerifier.trustAnchors`, `imprint.*`, `holderKey`, `issuerKey`, `credentialTemplates` and `importCredentials`

### Changed

- Deploys eudi-dev 2.6.0
- Probes call `/healthz` (liveness, startup) and `/readyz` (readiness, checks the storage backend)
- Requests to in-cluster services bypass the outbound proxy, and a restricted NetworkPolicy allows egress on the proxy ports
- Warns when `demo.enabled` is combined with an outbound proxy

## [0.1.0] - 2026-10-03

- Initial release for eudi-dev 2.5.1
