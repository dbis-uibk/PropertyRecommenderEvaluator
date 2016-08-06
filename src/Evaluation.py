""" Main file for evaluation framework for property recommender systems. """
import argparse
#import configparser
import json
import os
import pprint
import time
import mysql.connector

from MySQLRecommender import MySQLRecommender
from ResultAggregator import ResultAggregator
from RuleEvaluation import RuleEvaluation

""" MAIN FILE """
def main():
    """ main file: reads all configuration and triggers whole evaluation and result
    aggregation procedure
    """
    configfiles = ['config.cfg', 'algorithms.cfg']
    config = configparser.ConfigParser()
    config.read(configfiles)
    if len(config) < len(configfiles):
        raise ValueError("Failed to open/find all files")

    """ parse command line arguments """
    argparser = argparse.ArgumentParser(description="Property Recommender Evaluation")
    argparser.add_argument('-o', '--output_folder', dest='output_folder',
                           help='folder to store results in; if it does not exist it '
                                'will be created.',
                           required=True)
    argparser.add_argument('-v', '--verbose', dest='verbose', action='store_true',
                           help="verbose output.")
    args = argparser.parse_args()

    """ check if output folder exists, else create it """
    if not os.path.isabs(args.output_folder):
        args.output_folder = os.path.join(os.getcwd(), args.output_folder)
    if not os.path.isdir(args.output_folder):
        print("Output folder does not exist, creating it")
        os.makedirs(args.output_folder)

    """ connect to database, credentials taken from config file """

    conn = mysql.connector.connect(user=config['database']['user'],
                                   password=config['database']['password'],
                                   host=config['database']['host'],
                                   database=config['database']['database'],
                                   port=config['database']['port'])

    """ parse complex config values """
    evaluated_top_k_values = [int(x) for x in config['evaluation'][
        'evaluatedNoOfRecommendations'].split(',')]
    classifying_properties = config['evaluation']['classifyingProperties'].split(",")
    measures = [x.strip() for x in config['evaluation']['measures'].split(",")]

    """ set recommender parameters """
    recommender = MySQLRecommender(conn)
    recommender.evaluated_top_k_values = evaluated_top_k_values
    recommender.recommendation_algorithm = config['evaluation']['recommendationAlgorithm']
    recommender.classifying_properties = classifying_properties
    recommender.recommender_templates = config._sections['algorithms']
    recommender.max_no_recommendations = int(config['evaluation']['noOfRecommendations'])

    """ create evaluator object """
    evaluator = RuleEvaluation(recommender)
    evaluator.evaluated_top_k_values = evaluated_top_k_values
    evaluator.long_tail_limit = int(config['evaluation']['longTailLimit'])
    evaluator.initial_no_properties = int(config['evaluation']['initial_no_properties_per_subject'])
    evaluator.evaluation_measures = measures

    print("starting evaluation...\n")
    results = evaluator.perform_evaluation(
        int(config['evaluation']['numberOfSubjectsToBeEvaluated']))

    print("\naggregating evaluation results...\n")
    aggregator = ResultAggregator(evaluator, results, measures)
    results = aggregator.aggregate()


    pretty_printer = pprint.PrettyPrinter(indent=2)
    for measure in measures + ['reconstruction', 'reconstructionTotal']:
        print("\n----- " + measure + " -----")
        pretty_printer.pprint(results[measure])

    """ write results to file """
    filename = "evaluation_" + config['evaluation']['recommendationAlgorithm'] + "_" +  \
               time.strftime("%Y%m%d-%H%M%S") + ".json"
    print("\nwriting evaluation results to " + os.path.join(args.output_folder, filename))
    with open(filename, 'wt') as out:
        json.dump(results, out, indent=2)
    conn.close()


if __name__ == "__main__":
    main()
