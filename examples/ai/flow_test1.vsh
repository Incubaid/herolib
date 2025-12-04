#!/usr/bin/env -S v -n -w -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.ai.client
import incubaid.herolib.ai.flow_calendar

prompt = 'Explain quantum computing in simple terms'

flow_calendar.start(mut coordinator, prompt)!
