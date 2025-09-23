/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Leonhard Kargl <leo.kargl@proton.me>
 */

namespace Detective.Algorithms {
    private int min3 (int i1, int i2, int i3) {
        if (i1 <= i2 && i1 <= i3) {
            return i1;
        } else if (i2 <= i1 && i2 <= i3) {
            return i2;
        } else {
            return i3;
        }
    }

    // https://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
    public int levenshtein_distance (string search_term, string compare_term) {
        // Weights are in integers, where larger numbers imply a further distance
        var deletion_weight = 1;
        var insertion_weight = 1;
        var substitution_weight = 2;

        // Declare working arrays
        var previous_row = new int[compare_term.length + 1];
        var current_row = new int[compare_term.length + 1];

        // Initialize row
        for (var i = 0; i <= compare_term.length; i++) {
            previous_row[i] = i;
        }

        // Calculate cost matrix
        for (var i = 0; i < search_term.length; i++) {
            current_row[0] = i + deletion_weight;

            for (var j = 0; j < compare_term.length; j++) {
                var deletion_cost = previous_row[j + 1] + deletion_weight;
                var insertion_cost = current_row[j] + insertion_weight;
                var substitution_cost = 0;

                if (search_term.get_char (i) == compare_term.get_char (j)) {
                    substitution_cost = previous_row[j];
                } else {
                    substitution_cost = previous_row[j] + substitution_weight;
                }

                current_row[j + 1] = min3(deletion_cost, insertion_cost, substitution_cost);
            }

            previous_row = current_row;
        }

        return previous_row[compare_term.length];
    }
}
