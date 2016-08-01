""" Module takes result of evaluation and computes aggregated statistics."""
from collections import defaultdict


class ResultAggregator(object):
    """ Class takes result of evaluation and computes aggregated statistics."""

    def __init__(self, evaluator, statistics, measures):
        """ Initializes ResultAggregator class and according variables.

        :param evaluator: RuleEvaluation object used for the evaluation.
        :type evaluator: RuleEvaluation
        :param statistics: Raw results of the evaluation run.
        :type statistics: dict
        :param measures: measures used for the evaluation.
        :type measures: list
        """

        self.evaluator = evaluator
        self.evaluation_result = statistics
        self.measures = measures

    def aggregate(self):
        """ Function triggers computation of aggregation functions for evaluation result. """

        """ compute reconstruction per top-k run """
        self.compute_top_k_reconstruction(self.evaluator.evaluated_top_k_values)

        """ aggregate all measures per top-k run """
        self.compute_top_k_aggregated_measures_per_subject(self.measures,
                                                           self.evaluator.evaluated_top_k_values)

        """ call requires compute_top_k_aggregated_measures_per_subject to have been called
        previously as the aggreagtion requires the values precomputed by the previous
         function call. """
        self.compute_top_k_aggregated_measures(
            self.measures + ['reconstruction', 'reconstructionTotal'],
            self.evaluator.evaluated_top_k_values)

        return self.evaluation_result

    def compute_top_k_aggregated_measures(self, measures, evaluated_top_k_values):
        """ Function computes average of given measures """
        values = {top_k: defaultdict(int) for top_k in evaluated_top_k_values}
        counters = {top_k: defaultdict(int) for top_k in evaluated_top_k_values}
        for _, subject_stats in self.evaluation_result['details'].items():
            for top_k in evaluated_top_k_values:
                for measure in measures:
                    values[top_k][measure] += \
                        subject_stats['topK'][top_k][measure]
                    counters[top_k][measure] += 1

        result = {}
        for measure in measures:
            result[measure] = {}
            self.evaluation_result[measure] = {}
            for top_k in evaluated_top_k_values:
                self.evaluation_result[measure][top_k] = \
                    values[top_k][measure] / counters[top_k][measure]

        return result

    def compute_top_k_aggregated_measures_per_subject(self, measures, evaluated_top_k_values):
        """ Function computes average of all given measures grouped by given top-k recommendation
        lists for each single subject and stores it in the subjects evaluation results section.

        :param measures: evaluation measures to be aggregated.
        :type measures: list
        :param evaluated_top_k_values: top-k values to be evaluated.
        :type evaluated_top_k_values: list
        """
        values = {top_k: defaultdict(int) for top_k in evaluated_top_k_values}
        counters = {top_k: defaultdict(int) for top_k in evaluated_top_k_values}

        for subject, subject_stats in self.evaluation_result['details'].items():
            for top_k in evaluated_top_k_values:
                for measure in measures:
                    steps = subject_stats["topK"][top_k]['steps'].keys()
                    for step in steps:
                        values[top_k][measure] += \
                            subject_stats['topK'][top_k]['steps'][step][measure]
                        counters[top_k][measure] += 1

                    self.evaluation_result['details'][subject]["topK"][top_k][measure] = \
                        values[top_k][measure] / counters[top_k][measure]

    def compute_top_k_reconstruction(self, evaluated_top_k_values):
        """ Function computes reconstruction values for top-k recommendations for each subject and
        stores result in evaluation result dict.

        :param evaluated_top_k_values: k-values to be evaluated for measure@k evaluation.
        :type evaluated_top_k_values: list
        """

        for subject, subject_stats in self.evaluation_result['details'].items():
            initial_no_of_properties = subject_stats["initial_no_of_properties"]
            no_removed_properties = subject_stats["removed_properties"]

            """ count how many recommendations were accepted """
            for top_k in evaluated_top_k_values:
                matches = sum(i > 0 for i in [x['precision'] for x in
                                              subject_stats['topK'][top_k]['steps'].values()])
                self.evaluation_result['details'][subject]["topK"][top_k][
                    'reconstruction'] = matches / no_removed_properties
                self.evaluation_result['details'][subject]["topK"][top_k][
                    'reconstructionTotal'] = (matches + initial_no_of_properties) / ( \
                    no_removed_properties + initial_no_of_properties)
                self.evaluation_result['details'][subject]["topK"][top_k][
                    'matchedRecommendations'] = matches
