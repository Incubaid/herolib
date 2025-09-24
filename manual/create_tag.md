
## how to tag a version and push

```bash
cd ~/Users/despiegk~/code/github/incubaid/herolib
git tag -a v1.0.4 -m "all CI is now working"
git add . -A ; git commit -m ... ; git pull ; git push origin v1.0.4
```