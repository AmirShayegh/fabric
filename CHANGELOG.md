# Changelog

## [1.6.0](https://github.com/AmirShayegh/fabric/compare/v1.5.0...v1.6.0) (2026-09-08)


### Features

* **attention-pulse:** occlusion-gated FabricAttentionPulse primitive ([11b50c1](https://github.com/AmirShayegh/fabric/commit/11b50c149c037f858bc796efd657913041c39caf))
* **catalogue:** add Graph Layout demo for FabricGraphLayoutEngine ([90eced8](https://github.com/AmirShayegh/fabric/commit/90eced879d16493af67b5a0f3b283425234a7358))
* **catalogue:** add Progress Pills, Micro Progress, and Completion Health demos ([a30195f](https://github.com/AmirShayegh/fabric/commit/a30195fda341495f5e511bf516a6718598576864))
* FabricGraphLayoutEngine -- reusable DAG layout with crossing reduction and port assignment ([2c3cc8c](https://github.com/AmirShayegh/fabric/commit/2c3cc8cbfe4fb33d6b135838257db8e63f09265b))
* FabricMicroProgress + FabricAccent.forCompletionHealth + FabricPill progress variant ([5886098](https://github.com/AmirShayegh/fabric/commit/58860988994d5e2fa04b02b7dd1026eb716fe6db))
* **pill:** progress fills pill background with accent border ([133e3d8](https://github.com/AmirShayegh/fabric/commit/133e3d8eab914f900c8d2fb1ae8f838f5debaf3b))


### Bug Fixes

* **catalogue:** use FabricColors.canvas instead of non-existent surfaceSecondary ([86fd426](https://github.com/AmirShayegh/fabric/commit/86fd4267e05e7814a203544a66e3754349fea3e3))
* **catalogue:** use path directly instead of wrapping in Path init ([965dc17](https://github.com/AmirShayegh/fabric/commit/965dc17190beb0307accb237c9273349dd48a9db))
* **disclosure-group:** increase content top padding from xs to sm for better spacing ([3c698f3](https://github.com/AmirShayegh/fabric/commit/3c698f34d928126733a6127a892c6552aa318210))
* **pulse-ring:** cancel by identity change, not transaction ([fb8c133](https://github.com/AmirShayegh/fabric/commit/fb8c1339a35809fd82decc0b9ec32b39c8ebaa02))
* **pulse-ring:** defer initial occlusion report one main-actor turn ([31ff554](https://github.com/AmirShayegh/fabric/commit/31ff5542187d3ac1ce020cf42a1a8e711e142500))
* **pulse-ring:** gate pulse animation on window occlusion (ISS-740) ([dffd002](https://github.com/AmirShayegh/fabric/commit/dffd002878c7c0963b21852fa03ea690d03979d8))
* **pulse-ring:** selector-based occlusion observer for strict-concurrency deinit ([e54ad71](https://github.com/AmirShayegh/fabric/commit/e54ad718144177de827d1b148e4e172a1530deba))
* **timeline:** connector hand-off gradient fades toward the current node, not away from it ([5025bc5](https://github.com/AmirShayegh/fabric/commit/5025bc56765ff267c2c0c8b9d39452557e200c60))

## [1.5.0](https://github.com/AmirShayegh/fabric/compare/v1.4.0...v1.5.0) (2026-04-24)


### Features

* **colors:** editorialRed + editorialAmber + editorialPlum accents ([941c881](https://github.com/AmirShayegh/fabric/commit/941c881234500723ef6f0ad5603b8fa4b24d342d))

## [1.4.0](https://github.com/AmirShayegh/fabric/compare/v1.3.0...v1.4.0) (2026-04-24)


### Features

* **accents:** editorial FabricAccent cases + optional icon in FabricBadge ([07994c6](https://github.com/AmirShayegh/fabric/commit/07994c6115db7da0cc51475520929df0ecc87ac2))

## [1.3.0](https://github.com/AmirShayegh/fabric/compare/v1.2.0...v1.3.0) (2026-04-24)


### Features

* **colors:** add editorial palette tokens (hex-keyed) ([cdb8fdb](https://github.com/AmirShayegh/fabric/commit/cdb8fdb2efd5162d2a77062eb95278de669bce39))

## [1.2.0](https://github.com/AmirShayegh/fabric/compare/v1.1.0...v1.2.0) (2026-04-23)


### Features

* **timeline:** add titleLineLimit modifier (vertical-only) ([3fc7582](https://github.com/AmirShayegh/fabric/commit/3fc7582fb466819facb0cfb50bb0152f1bde7de7))

## [1.1.0](https://github.com/AmirShayegh/fabric/compare/v1.0.1...v1.1.0) (2026-04-23)


### Features

* **timeline:** add labelMaxWidth to clamp vertical label column width ([bf8cb52](https://github.com/AmirShayegh/fabric/commit/bf8cb52dead1f0eb9353fd3ac6e6335d4128f475))
