""" Module performs evaluation of association rule-based recommendations for a given ruleset
    stored in a MySQL/MariaDB database. """
from _collections import OrderedDict
from ProgressBar import ProgressBar


class RuleEvaluation(object):
    """ Class performs evaluation of association rule-based recommendations for a given ruleset
    stored in a MySQL/MariaDB database.
    """

    def __init__(self, recommender):
        """Initializess RuleEvaluation class and according variables.

        :param recommender: the recommender class to be used for computing recommendations
        which are evaluated using this class.
        :type recommender: MySQLRecommender
        """

        self.recommender = recommender
        self.evaluated_top_k_values = []
        self.stats = {'subjects': 0, 'processed_subjects': 0}
        self.evaluation_measures = None
        self.long_tail_limit = None
        self.stats['details'] = {}
        self.classifying_property_ids = None
        self.initial_no_properties = 0

    def perform_evaluation(self, no_evaluated_subjects=1000):
        """ Function triggers actual evaluation of subjects.

        :param no_evaluated_subjects: number of subjects to be evaluated
        :type no_evaluated_subjects: int .

        :returns: results of the overall evaluation run.
        :rtype: dict
        """
        self.classifying_property_ids = self.recommender.get_classifying_property_ids()
        random_subjects = self.recommender.get_random_subjects(no_evaluated_subjects)
        progress_bar = ProgressBar(no_evaluated_subjects, 100)
        for curr_subject in random_subjects:
            # print("Processing subject: " + curr_subject['subject_title'])
            progress_bar.advance()
            self.process_subject(curr_subject['subject_id'])

        return self.stats

    def process_subject(self, subject_id):
        """ Function processes evaluation for a single given subject. This includes randomly
        choosing properties used as input for recommendation evaluation, filtering for classifying
        properties and calling the actual evaluation.

        :param: subject_id: the id of the subject to be evaluated
        :type subject_id: int
        """

        self.stats['subjects'] += 1
        """" get all properties occuring on current subject """
        properties_objects = self.recommender.get_subject_properties_objects(
            subject_id, self.long_tail_limit)

        """ intersected array contains only items if classifying properties are defined """
        contained_classifying_properties = (
            set(properties_objects.keys()).intersection(set(self.classifying_property_ids)))
        classifying_properties_objects = {key: properties_objects[key] for key in
                                          contained_classifying_properties}

        """ gather first <initial_no_properties> property-object elements (in given order) and
        merge dictionary with classifying properties to make sure to not exclude any
        classifying properties  """
        initial_properties_objects = OrderedDict(
            list(properties_objects.items())[:self.initial_no_properties])
        input_properties_objects = initial_properties_objects.copy()
        input_properties_objects.update(classifying_properties_objects)

        """ at least initial_no_properties + 1 required """
        if len(properties_objects) > len(input_properties_objects):
            self.stats['processed_subjects'] += 1
            """ choose three random (ordered by randomly generated column idx) """
            """ if it is a classified algorithm, add classifying properties """
            removed_properties_set = list(
                set(properties_objects.keys()).difference(set(input_properties_objects.keys())))
            removed_properties = [x for x in properties_objects if x in removed_properties_set]

            self.stats['details'][subject_id] = {}
            self.stats['details'][subject_id] = self.perform_evaluation_on_subject(
                input_properties_objects,
                removed_properties)
            self.stats['details'][subject_id]['removed_properties'] = len(removed_properties)
            self.stats['details'][subject_id][
                'initial_no_of_properties'] = self.initial_no_properties

    def perform_evaluation_on_subject(self, input_properties, removed_properties):
        """ Function performs the actual recommendation and evaluation steps. Takes set of
        properties as input and computes recommendations for these properties. If at least one of
        the recommendations matches, we accept it and add it to the set of propreties on the
        subject and repeat this evaluation iteratively (while evaluating the recommendation
        performance at each step).

        :param input_properties: initial properties to be used as input for the first
        recommendation computation.
        :param removed_properties: ground truth data that should be reconstructed during
        evaluation process.
        :return: computed results/statistics for evaluation on given subject
        :rtype: dict
        """

        curr_properties_on_subject = input_properties
        step = 0
        continue_top_k = {}
        stats = {'topK': {}}
        """ fill evaluation_result dict with empty dicts"""
        for top_k in self.evaluated_top_k_values:
            stats['topK'][top_k] = {'steps': {}}
            continue_top_k[top_k] = True

        """ loop until no more matching recommendations can be found """
        while True:
            recommendations = self.recommender.get_recommendations(curr_properties_on_subject)
            for top_k in self.evaluated_top_k_values:
                """ if top_k still active """
                if continue_top_k[top_k]:
                    """ evaluation recommendations and decide if we proceed to next step """
                    top_k_results = self.evaluate_recommended_properties(recommendations[:top_k],
                                                                         removed_properties,
                                                                         top_k)
                    """ nothing found, stop top_k run """
                    if top_k_results['precision'] == 0.0:
                        continue_top_k[top_k] = False
                    stats['topK'][top_k]['steps'][step] = top_k_results

            """ process reccommendations and choose one property; procede if at least one suitable
            property was found """
            loop_continue = False
            matching_properties_set = list(set(recommendations).intersection(set(
                removed_properties)))
            matching_properties = [x for x in removed_properties if x in matching_properties_set]

            if len(matching_properties) > 0:
                """ choose the first suitable property, add it to current set and
                remove it from the removed set """
                chosen_property = matching_properties[0]
                curr_properties_on_subject[chosen_property] = None
                removed_properties_set = list(
                    set(removed_properties).difference({chosen_property}))
                removed_properties = [x for x in removed_properties if x in removed_properties_set]

                """ as we added one property to the current set, continue and compute
                recommendations again """
                loop_continue = True
                step += 1
            if not loop_continue or not len(removed_properties) > 0:
                break
        return stats

    def evaluate_recommended_properties(self, recommended_properties, removed_properties,
                                        maximum_number_recommendations):
        """Function computes evaluation metrics for given recommendations and previously removed
        properties (ground truth). Evaluation metrics include recall, precision and mean
        reciprocal rank.

        :param recommended_properties: list of computed recommendations.
        :type recommended_properties: list
        :param removed_properties: list of previously removed properties
        :type removed_properties: list
        :param maximum_number_recommendations: maximum number of recommendations computed
        :type maximum_number_recommendations: int

        :returns: dict containing recall, precision and reciprocal rank results.
        :rtype: dict
        """

        precision = 0.0
        recall = 0.0
        mean_reciprocal_rank = 0.0

        if len(recommended_properties) > 0:
            """correct property recommendations are those contained in list of removed
            properties """
            no_correct_recommendations = len(
                set(removed_properties).intersection(set(recommended_properties)))
            precision = no_correct_recommendations / len(recommended_properties)
            recall = no_correct_recommendations / min(len(removed_properties),
                                                      maximum_number_recommendations)
            mean_reciprocal_rank = self.compute_mean_reciprocal_rank(recommended_properties,
                                                                     removed_properties)

        return {
            'precision'     : precision,
            'recall'        : recall,
            'reciprocalRank': mean_reciprocal_rank}

    def compute_mean_reciprocal_rank(self, recommended_properties, removed_properties):
        """Function computes the mean reciprocal rank for the given list of recommendations
        and the ground truth data provided (i.e., previously removed properties).

        :param recommended_properties: list of computed recommendations.
        :type recommended_properties: list
        :param removed_properties: list of previously removed properties (ground truth).
        :type removed_properties: list

        :returns: mean reciprocal rank
        :rtype: float
        """

        mean_reicprocal_rank = 0.0
        """ loop over all recommended items and compute mean reciprocal rank """
        for i in range(0, len(recommended_properties)):
            if recommended_properties[i] in removed_properties:
                mean_reicprocal_rank += (1 / (i + 1))
        return mean_reicprocal_rank
