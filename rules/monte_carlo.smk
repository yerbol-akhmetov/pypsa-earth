# SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later


rule monte_carlo:
    params:
        monte_carlo=config["monte_carlo"],
    input:
        network=rules.prepare_network.output.network,
    output:
        network="networks/" + RDIR + "elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}.nc",
    log:
        "logs/"
        + RDIR
        + "prepare_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}.log",
    benchmark:
        (
            "benchmarks/"
            + RDIR
            + "prepare_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}"
        )
    threads: 1
    resources:
        mem_mb=4000,
    script:
        scripts("monte_carlo.py")


rule solve_monte:
    input:
        expand(rules.monte_carlo.output.network, **config["scenario"]),


rule solve_network:
    params:
        solving=config["solving"],
        augmented_line_connection=config["augmented_line_connection"],
        policy_config=config["policy_config"],
    input:
        network=rules.monte_carlo.output.network,
        agg_p_nom_minmax=config["electricity"]["agg_p_nom_limits"]["file"],  # ensure the CSV with capacity constraints is copied into the shadow directory (needed on Windows, since shadowed scripts can’t access files outside `input`)
    output:
        network="results/" + RDIR + "networks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}.nc",
    log:
        solver=os.path.normpath(
            "logs/"
            + RDIR
            + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}_solver.log"
        ),
        python="logs/"
        + RDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}_python.log",
        memory="logs/"
        + RDIR
        + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}_memory.log",
    benchmark:
        (
            "benchmarks/"
            + RDIR
            + "solve_network/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{unc}"
        )
    threads: 20
    resources:
        mem_mb=memory,
    shadow:
        "copy-minimal" if os.name == "nt" else "shallow"
    script:
        scripts("solve_network.py")


rule solve_all_networks_monte:
    input:
        expand(rules.solve_network.output.network, **config["scenario"]),
