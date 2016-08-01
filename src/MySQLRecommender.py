""" Module performs actual recommendation for evaluation. """
from collections import OrderedDict


class MySQLRecommender(object):
    """ Class performs actual recommendation for evaluation. """
    def __init__(self, conn):
        self.conn = conn
        self.evaluated_top_k_values = None
        self.hybrid_alpha = None
        self.recommendation_algorithm = None
        self.classifying_properties = None
        self.recommender_templates = None
        self.max_no_recommendations = None

    def get_classifying_property_ids(self):
        """ Function retrieves ids for classifying properties (specified via text).

        :return: classifying properties
        :rtype: list
        """
        property_ids = []
        cursor = self.conn.cursor(buffered=True)
        cursor.execute(
            "SELECT prop_id FROM dict_prop WHERE prop_text IN ('%s');" % (
                '\',\''.join(self.classifying_properties)))
        for property_id in cursor:
            property_ids.append(property_id[0])
        cursor.close()
        return self.classifying_properties

    def get_random_subjects(self, no_subjects=1000, subject_offset=0):
        """ Retrieve random subjects from MySQL.

        :param no_subjects: number of random subjects to be retrieved
        :type no_subjects: int
        :param subject_offset: offset to be used for retrieving random subjects
        :type subject_offset: int

        :return: random subjects (id and text)
        :rtype: list
        """
        subjects = []
        cursor = self.conn.cursor(buffered=True)
        cursor.execute(
            'SELECT sub_id, sub_text FROM dict_sub WHERE sub_exclude = 1 ORDER BY sub_text LIMIT '
            '%d,%d' % (
                subject_offset, no_subjects))
        for subject in cursor:
            subjects.append({"subject_id": subject[0], 'subject_title': subject[1]})
        cursor.close()
        return subjects

    def get_subject_properties_objects(self, subject_id, long_tail_limit):
        """ Retrieves set of properties and according objects appearing on given subject.
        Only retrieves subjects with number of properties > long_tail_limit.

        :param subject_id: id of subject to retrieve properties and objects for.
        :type subject_id: int
        :param long_tail_limit: minimum number of properties appearing on subject
        :type long_tail_limit: int

        :returns: properties and objects of given subject
        :rtype: dict
        """
        properties = OrderedDict()

        sql = "SELECT t.prop_id as prop_id, t.obj_id AS obj_id " \
              "FROM triple_reconstruct as t " \
              "LEFT JOIN dict_prop as p USING (prop_id) " \
              "WHERE sub_id = %d AND prop_count > %d " \
              "ORDER BY idx ASC" % (subject_id, long_tail_limit)
        cursor = self.conn.cursor(buffered=True)
        cursor.execute(sql)
        for prop_id, obj_id in cursor:
            if prop_id in properties:
                properties[prop_id].append(obj_id)
            else:
                properties[prop_id] = [obj_id]
        cursor.close()
        return properties

    def get_recommendations(self, properties_objects):
        """ Function computes recommendations based on given rules and the given
        recommendation algorithm.

        :param properties_objects: properties and objects appearing on subject to be evaluated
        :type properties_objects: dict
        :returns: property recommendations
        :rtype: list
         """
        recommendations = []

        properties = ','.join([str(x) for x in properties_objects.keys()])

        cursor = self.conn.cursor(buffered=True)
        if 'classified' in self.recommendation_algorithm:
            classified_condition = self.get_classified_condition_statement(properties_objects)
            sql_data = (classified_condition, properties, self.max_no_recommendations)
        else:
            sql_data = (properties, properties, self.max_no_recommendations)

        sql = self.recommender_templates[self.recommendation_algorithm] % (sql_data)

        cursor.execute(sql)

        for prop_id in cursor:
            recommendations.append(prop_id[0])
        cursor.close()
        return recommendations

    def get_classified_condition_statement(self, property_objects):
        """ Function builds SQL statement for including classifying properties in the
        recommendation computation process.

        :param property_objects: properties and according objects on current subject
        :type property_objects: dict

        :returns: SQL-string to include classifying properties (WHERE-clause).
        :rtype: string
        """

        conditions = []
        for prop_id, objects in property_objects.items():
            if (objects is not None) and prop_id in self.classifying_properties:
                for curr_object in objects:
                    conditions.append(
                        "( head" + str(prop_id) + " AND object = " + str(curr_object) + " )")
            else:
                conditions.append("( head = " + str(prop_id) + " )")

        return " OR ".join(conditions)
