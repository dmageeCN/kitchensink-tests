#!/bin/bash

# Parses the raw IMB-MPI1 Biband output produced by run_perftest.sh
# (OPX-*.out files under $HOME/perftest) into a CSV per input file,
# written alongside it (same name, .csv extension instead of .out).
#
# Each CSV is indexed by "Size" (the #bytes column) with one value column
# per iteration, titled 1, 2, 3, ... . Cell value is the Mbytes/sec result.
# Iterations that ended early (e.g. the run was killed mid-table, or a rank
# died) are dropped entirely rather than included with blank cells.

PERFDIR=${1-:"$HOME/perftest"}

# Parses a single OPX output file into a CSV next to it.
parse_size() {
    local in_file=$1
    local out_csv="${in_file%.out}.csv"

    awk '
        # New iteration block starts here; bump the global iteration counter.
        /ITERATION [0-9]+/ {
            iter++
            next
        }
        # Start of the results table.
        /^[[:space:]]*#bytes/ {
            in_table = 1
            next
        }
        # Blank line ends the table.
        in_table && NF == 0 {
            in_table = 0
            next
        }
        in_table {
            size = $1
            if (size == 0) next
            mbps = $3
            if (!(size in seen)) {
                seen[size] = 1
                order[++n] = size
            }
            val[size, iter] = mbps
        }
        # Only iterations that reach MPI_Finalize ran to completion.
        /All processes entering MPI_Finalize/ {
            complete[iter] = 1
        }
        END {
            # Build the list of complete iterations, renumbered sequentially.
            ncols = 0
            for (i = 1; i <= iter; i++) {
                if (i in complete) cols[++ncols] = i
            }
            printf "Size"
            for (c = 1; c <= ncols; c++) printf ",%d", c
            printf "\n"
            for (k = 1; k <= n; k++) {
                s = order[k]
                printf "%s", s
                for (c = 1; c <= ncols; c++) {
                    i = cols[c]
                    printf ",%s", val[s, i]
                }
                printf "\n"
            }
        }
    ' "$in_file" > "$out_csv"

    echo "Wrote $out_csv"
}

for f in $(find "$PERFDIR" -type f -name 'OPX*.out'); do
    parse_size "$f"
done
