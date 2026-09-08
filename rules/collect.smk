# SPDX-FileCopyrightText:  PyPSA-Earth and PyPSA-Eur Authors
#
# SPDX-License-Identifier: AGPL-3.0-or-later


rule solve_all_networks:
    input:
        expand(
            "results/" + RDIR + "networks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}.nc",
            **config["scenario"],
        ),


rule plot_all_p_nom:
    input:
        expand(
            "results/"
            + RDIR
            + "plots/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_p_nom.{ext}",
            **config["scenario"],
            ext=["png", "pdf"],
        ),


rule make_all_summaries:
    input:
        expand(
            "results/"
            + RDIR
            + "summaries/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{country}",
            **config["scenario"],
            country=["all"] + config["countries"],
        ),


rule plot_all_summaries:
    input:
        expand(
            "results/"
            + RDIR
            + "plots/summary_{summary}_elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{country}.{ext}",
            summary=["energy", "costs"],
            **config["scenario"],
            country=["all"] + config["countries"],
            ext=["png", "pdf"],
        ),


rule prepare_sector_networks:
    input:
        expand(
            RESDIR
            + "prenetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
            **config["scenario"],
            **config["costs"],
        ),


rule solve_sector_networks:
    input:
        expand(
            RESDIR
            + "postnetworks/elec_s{simpl}_{clusters}_ec_l{ll}_{opts}_{sopts}_{planning_horizons}_{discountrate}.nc",
            **config["scenario"],
            **config["costs"],
        ),
