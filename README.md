```sh
TMP=$(mktemp -d) \
  && git clone --depth 1 "https://github.com/shiradofu/pp.git" "$TMP" \
  && bash "$TMP/setup.sh" \
  && rm -rf "$TMP"
```
