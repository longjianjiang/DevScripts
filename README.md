# DevScripts

- generateAPIManagers

Create apimanager header file and source file, add them to xcode projet with [Xcodeproj](https://github.com/CocoaPods/Xcodeproj).

- generateAssets

Move images to a folder, add scripts at build phase, automatically udpate xcassets.

- updatePodspec

Update podspec version, commit, add tag, push origin.

`sh updatePodspec.sh <podspec's path>`

```
Current version is 1.11
Enter new version:
1.12
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Delta compression using up to 8 threads
Compressing objects: 100% (3/3), done.
Writing objects: 100% (3/3), 286 bytes | 286.00 KiB/s, done.
Total 3 (delta 2), reused 0 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:longjianjiang/xxx.git
   c7327d1..b9d9a3d  master -> master
Total 0 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:longjianjiang/xxx.git
 * [new tag]         1.12 -> 1.12
Success.
```

