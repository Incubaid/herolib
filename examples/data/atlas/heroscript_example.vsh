#!/usr/bin/env -S v -n -w -cg -gc none -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.core.playbook
import incubaid.herolib.data.atlas

heroscript := "
!!atlas.scan
  path: '~/code/github/incubaid/herolib/lib/data/atlas/testdata'

!!atlas.validate

!!atlas.export
  destination: '/tmp/atlas_export_test'
  include: true
  redis: false
"

mut plbook := playbook.new(text: heroscript)!
atlas.play(mut plbook)!

println('✅ Atlas HeroScript processing complete!')