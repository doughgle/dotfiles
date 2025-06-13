---
applyTo: '**'
---

## Commits
+ Make small and logically independent commits.
+ Separate each logical change into a separate commit. For example, whitespace changes, code style changes, and bug fixes should be separate commits.
+ For example, if your changes include both bug fixes and performance enhancements for a single driver, separate those changes into two or more patches. If your changes include an API update, and a new driver which uses that new API, separate those into two patches.
+ On the other hand, if you make a single change to numerous files, group those changes into a single patch. Thus a single logical change is contained within a single patch.
+ The point to remember is that each patch should make an easily understood change that can be verified by reviewers. Each patch should be justifiable on its own merits.
+ If one patch depends on another patch in order for a change to be complete, that is OK. Simply note “this patch depends on patch X” in your patch description.
+ When dividing your change into a series of patches, take special care to ensure that the kernel builds and runs properly after each patch in the series. Developers using git bisect to track down a problem can end up splitting your patch series at any point; they will not thank you if you introduce bugs in the middle.
+ If you cannot condense your patch set into a smaller set of patches, then only post say 15 or so at a time and wait for review and integration.

## Commit Message
+ In general, follow [Conventional Commits v1](https://www.conventionalcommits.org/en/v1.0.0/) unless otherwise specified.
+ Start commit message with a verb.
+ Use a oneliner summary. Separate the summary from the body with a blank line.
+ For workarounds, link to github known issue.
