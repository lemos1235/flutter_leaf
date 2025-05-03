#ifndef LEAF_H
#define LEAF_H

#include <stdbool.h>
#include <stdint.h>

/**
 * Starts leaf with options, on a successful start this function blocks the current
 * thread.
 *
 * @note This is not a stable API, parameters will change from time to time.
 *
 * @param rt_id A unique ID to associate this leaf instance, this is required when
 *              calling subsequent FFI functions, e.g. reload, shutdown.
 * @param config_path The path of the config file, must be a file with suffix .conf
 *                    or .json, according to the enabled features.
 * @param auto_reload Enabls auto reloading when config file changes are detected,
 *                    takes effect only when the "auto-reload" feature is enabled.
 * @param multi_thread Whether to use a multi-threaded runtime.
 * @param auto_threads Sets the number of runtime worker threads automatically,
 *                     takes effect only when multi_thread is true.
 * @param threads Sets the number of runtime worker threads, takes effect when
 *                     multi_thread is true, but can be overridden by auto_threads.
 * @param stack_size Sets stack size of the runtime worker threads, takes effect when
 *                   multi_thread is true.
 * @return ERR_OK on finish running, any other errors means a startup failure.
 */
int32_t leaf_run_with_options(uint16_t rt_id,
                              const char *config_path,
                              bool auto_reload,
                              bool multi_thread,
                              bool auto_threads,
                              int32_t threads,
                              int32_t stack_size);

/**
 * Starts leaf with a single-threaded runtime, on a successful start this function
 * blocks the current thread.
 *
 * @param rt_id A unique ID to associate this leaf instance, this is required when
 *              calling subsequent FFI functions, e.g. reload, shutdown.
 * @param config_path The path of the config file, must be a file with suffix .conf
 *                    or .json, according to the enabled features.
 * @return ERR_OK on finish running, any other errors means a startup failure.
 */
int32_t leaf_run(uint16_t rt_id, const char *config_path);

/**
 * Starts leaf with a config string, on a successful start this function blocks the current
 * thread.
 *
 * @param rt_id A unique ID to associate this leaf instance, this is required when
 *              calling subsequent FFI functions, e.g. reload, shutdown.
 * @param config The config string.
 * @return ERR_OK on finish running, any other errors means a startup failure.
 */
int32_t leaf_run_with_config_string(uint16_t rt_id, const char *config);

/**
 * Reloads DNS servers, outbounds and routing rules from the config file.
 *
 * @param rt_id The ID of the leaf instance to reload.
 *
 * @return Returns ERR_OK on success.
 */
int32_t leaf_reload(uint16_t rt_id);

/**
 * Shuts down leaf.
 *
 * @param rt_id The ID of the leaf instance to reload.
 *
 * @return Returns true on success, false otherwise.
 */
bool leaf_shutdown(uint16_t rt_id);

#endif /* LEAF_H */ 