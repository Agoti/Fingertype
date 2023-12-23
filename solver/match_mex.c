// THESE CODES ARE NOT USED --Monster Kid
// skip this file

#include "mex.h"
#include "matrix.h"
#include "math.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    // Input variables
    double *minutiae_1 = mxGetPr(prhs[0]);
    double *minutiae_2 = mxGetPr(prhs[1]);
    double dist_threshold = mxGetScalar(prhs[2]);
    double angle_threshold = mxGetScalar(prhs[3]);
    double penalty_unmatched_minutiae = mxGetScalar(prhs[4]);
    double penalty_rotation = mxGetScalar(prhs[5]);
    double penalty_translation = mxGetScalar(prhs[6]);

    // Get the dimensions of the input matrices
    int rows_1 = mxGetM(prhs[0]);
    int cols_1 = mxGetN(prhs[0]);
    int rows_2 = mxGetM(prhs[1]);
    int cols_2 = mxGetN(prhs[1]);

    // Output variables
    double *matching_score;
    double *A;
    double *B;
    double *matched_pts1;
    double *matched_pts2;

    // Create output matrices
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(2, 2, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(2, 1, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(rows_1, 2, mxREAL);
    plhs[4] = mxCreateDoubleMatrix(rows_2, 2, mxREAL);

    // Get pointers to the output matrices
    matching_score = mxGetPr(plhs[0]);
    A = mxGetPr(plhs[1]);
    B = mxGetPr(plhs[2]);
    matched_pts1 = mxGetPr(plhs[3]);
    matched_pts2 = mxGetPr(plhs[4]);

    // Initialize transformation
    double max_A[4] = {1, 0, 0, 1};
    double max_B[2] = {0, 0};
    double* max_matched_1 = (double*)malloc(rows_1 * 2 * sizeof(double));
    double* max_matched_2 = (double*)malloc(rows_2 * 2 * sizeof(double));
    
    // Initialize transformed minutiae
    double* minutiae_2_transformed = (double*)malloc(rows_2 * 3 * sizeof(double));

    // Iterative matching
    double max_score = -INFINITY;
    for (int i = 0; i < rows_1; ++i) {
        for (int j = 0; j < rows_2; ++j) {
            double score = 0;
            double* matched_1 = (double*)malloc(rows_1 * 2 * sizeof(double));
            double* matched_2 = (double*)malloc(rows_2 * 2 * sizeof(double));
            int n_matched_1 = 0;
            int n_matched_2 = 0;
            double* is_matched_1 = (double*)malloc(rows_1 * sizeof(double));
            double* is_matched_2 = (double*)malloc(rows_2 * sizeof(double));
            memset(is_matched_1, 0, sizeof(is_matched_1));
            memset(is_matched_2, 0, sizeof(is_matched_2));

            // Calculate affine transformation
            double dx = minutiae_1[i] - minutiae_2[j];
            double dy = minutiae_1[i + rows_1] - minutiae_2[j + rows_2];
            double dtheta = minutiae_1[i + 2 * rows_1] - minutiae_2[j + 2 * rows_2];
            double cos_dtheta = cos(dtheta);
            double sin_dtheta = sin(dtheta);
            A[0] = cos_dtheta;
            A[1] = -sin_dtheta;
            A[2] = sin_dtheta;
            A[3] = cos_dtheta;
            B[0] = dx;
            B[1] = dy;

            // Transform image 1_2
            for (int k = 0; k < rows_2; ++k) {
                double x = minutiae_2[k];
                double y = minutiae_2[k + rows_2];
                minutiae_2_transformed[k] = cos_dtheta * x - sin_dtheta * y + dx;
                minutiae_2_transformed[k + rows_2] = sin_dtheta * x + cos_dtheta * y + dy;
                minutiae_2_transformed[k + 2 * rows_2] = minutiae_2[k + 2 * rows_2] + dtheta;
            }

            // Calculate matching score
            // Matching score = number of matched minutiae
            for (int k = 0; k < rows_1; ++k) {
                for (int l = 0; l < rows_2; ++l) {
                    double dist = sqrt(pow(minutiae_1[k] - minutiae_2_transformed[l], 2) +
                                       pow(minutiae_1[k + rows_1] - minutiae_2_transformed[l + rows_2], 2));
                    double angle_diff = fabs(minutiae_1[k + 2 * rows_1] - minutiae_2_transformed[l + 2 * rows_2]);
                    if (dist < dist_threshold && angle_diff < angle_threshold &&
                        is_matched_1[k] == 0 && is_matched_2[l] == 0) {
                        score += 1;
                        n_matched_1 += 1;
                        n_matched_2 += 1;
                        matched_1[2 * n_matched_1 - 2] = minutiae_1[k];
                        matched_1[2 * n_matched_1 - 1] = minutiae_1[k + rows_1];
                        is_matched_1[k] = 1;
                        is_matched_2[l] = 1;
                    }
                }
            }

            // Update matching score
            // Incur penalty for unmatched minutiae and affine transformation
            score -= penalty_unmatched_minutiae * (rows_1 - sum(is_matched_1));
            score -= penalty_unmatched_minutiae * (rows_2 - sum(is_matched_2));
            score -= penalty_rotation * fabs(dtheta) * 180 / M_PI;
            score -= penalty_translation * (fabs(dx) + fabs(dy));

            // Update maximum score
            if (score > max_score) {
                max_score = score;
                memcpy(A, max_A, sizeof(max_A));
                memcpy(B, max_B, sizeof(max_B));
                memcpy(matched_pts1, max_matched_1, sizeof(max_matched_1));
                memcpy(matched_pts2, max_matched_2, sizeof(max_matched_2));
            }
            free(matched_1);
            free(matched_2);
            free(is_matched_1);
            free(is_matched_2);
        }
    }

    free(max_matched_1);
    free(max_matched_2);
    free(minutiae_2_transformed);

    // Return result
    *matching_score = max_score;
}

