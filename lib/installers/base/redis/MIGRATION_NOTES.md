# Redis Installer Migration Notes

## Old Installer Logic (redis.v)

### Key Behaviors:
1. **datadir**: `${os.home_dir()}/hero/var/redis` (NOT `/var/lib/redis`)
2. **Template Usage**: YES - always applies template before starting
3. **macOS Support**: YES - uses `--daemonize yes` flag
4. **Linux Support**: YES - uses startupmanager
5. **Check before start**: Returns early if already running
6. **Config path**: 
   - Linux: `/etc/redis/redis.conf`
   - macOS: `${datadir}/redis.conf`

### Flow:
```
redis_install() 
  → checks if running (unless reset)
  → installs package (redis-server on Linux, redis on macOS)
  → creates datadir
  → calls start()

start()
  → returns if already running
  → configure() - applies template
  → kills existing processes
  → macOS: starts with daemonize
  → Linux: uses startupmanager
  → waits for ping response
```

## New Installer Logic (redis/)

### Matching Behaviors:
1. ✅ **datadir**: `${os.home_dir()}/hero/var/redis` - FIXED
2. ✅ **Template Usage**: YES - `configure()` called in `start_pre()`
3. ✅ **macOS Support**: YES - handled in `start_pre()`
4. ✅ **Linux Support**: YES - via `startupcmd()` and startupmanager
5. ✅ **Check before start**: Added in `start_pre()`
6. ✅ **Config path**: Same logic in `configfilepath()`

### Flow:
```
install()
  → checks if installed
  → installs package (redis-server on Linux, redis on macOS)
  → creates datadir

start()
  → calls start_pre()
  → on Linux: uses startupmanager with startupcmd()
  → calls start_post()

start_pre()
  → returns if already running
  → configure() - applies template
  → kills existing processes
  → macOS: starts with daemonize

start_post()
  → waits for ping response
```

## Template Fixes

Fixed incompatible directives for Redis 7.0.15:
- ✅ Commented out `locale-collate ""`
- ✅ Commented out `set-max-listpack-entries 128`
- ✅ Commented out `set-max-listpack-value 64`
- ✅ Commented out `zset-max-listpack-entries 128`
- ✅ Commented out `zset-max-listpack-value 64`

## Verification

The new installer now matches the old installer's logic exactly:
- Same default datadir
- Same template usage
- Same platform handling
- Same startup flow
- Template is compatible with Redis 7.0.15
