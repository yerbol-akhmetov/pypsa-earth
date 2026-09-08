# SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later


rule run_scenario:
    input:
        diff_config="configs/scenarios/config.{scenario_name}.yaml",
    output:
        touchfile=touch("results/{scenario_name}/scenario.done"),
        copyconfig="results/{scenario_name}/config.yaml",
    threads: 1
    resources:
        mem_mb=5000,
    run:
        from subprocess import run

        import yaml
        from build_test_configs import create_test_config

        # get base configuration file from diff config
        with open(input.diff_config) as f:
            base_config_path = (
                yaml.full_load(f)
                .get("run", {})
                .get("base_config", "config.default.yaml")
            )

            # Ensure the scenario name matches the name of the configuration
        create_test_config(
            input.diff_config,
            {"run": {"name": wildcards.scenario_name}},
            input.diff_config,
        )
        # merge the default config file with the difference
        create_test_config(base_config_path, input.diff_config, "config.yaml")
        run(
            "snakemake -j all solve_all_networks --rerun-incomplete",
            shell=True,
            check=not config["run"]["allow_scenario_failure"],
        )
        run(
            "snakemake -j1 make_statistics --force",
            shell=True,
            check=not config["run"]["allow_scenario_failure"],
        )
        copyfile("config.yaml", output.copyconfig)


rule run_all_scenarios:
    input:
        expand(
            "results/{scenario_name}/scenario.done",
            scenario_name=[
                c.stem.replace("config.", "")
                for c in Path("configs/scenarios").glob("config.*.yaml")
            ],
        ),
