# SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later


rule solve_sector_network:
    params:
        solving=config["solving"],
        augmented_line_connection=config["augmented_line_connection"],
        policy_config=config["policy_config"],
    input:
        network=rules.add_export.output.network,
        costs=rules.process_cost_data.output.costs.format(
            year="{planning_horizons}", scope="sec"
        ),
        configs=rules.copy_config.output.config,  # included to trigger copy_config rule
        agg_p_nom_minmax=config["electricity"]["agg_p_nom_limits"]["file"],  # ensure the CSV with capacity constraints is copied into the shadow directory (needed on Windows, since shadowed scripts can’t access files outside `input`)
    output:
        network=RESDIR
        + "postnetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
    shadow:
        "copy-minimal" if os.name == "nt" else "shallow"
    log:
        solver="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_solver.log",
        python="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_python.log",
        memory="logs/"
        + SECDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}_memory.log",
    threads: 25
    resources:
        mem_mb=config["solving"]["mem"],
    benchmark:
        (
            RESDIR
            + "benchmarks/solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}"
        )
    script:
        scripts("solve_network.py")
