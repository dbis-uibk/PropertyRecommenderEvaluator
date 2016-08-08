  
## PropertyRecommenderEvaluator
  
The PropertyRecommenderEvaluator is a python framework for the evaluation of property recommender sysems which aim at supporting users in adding information in collaborative environments based on the triple format (subject, property, object). Consider a user on Wikidata who is currently in the process of editing the subject „Innsbruck“ (a city in Austria) and has already entered values for the properties mayor and the number of inhabitants. A recommender system may assist the user in recommending further properties which might also be suitable for the given subject (e.g., about the founding year of the city). These recommendations are traditionally derived from similar subjects (in regards to the properties used) which contain properties that are not yet used on the given subject.
  
  The Python-framework at hand provides evaluating property recommendation approaches that rely on a set of precomputed association rules ([wikipedia article](https://en.wikipedia.org/wiki/Association_rule_learning)). Our framework provides the following features:
* import triple information extracted from a Wikidata JSON—dump to a MySQL database
* computation of association rules (stored in MySQL)
* creation and storage of a test set of random subjects (we store these for future comparisons of different algorithms and improved repeatability)
* evaluation framework for comparing [recall, precision](https://en.wikipedia.org/wiki/Precision_and_recall)  and [reconstruction]().
* detailed results exported to JSON including single results for every subject, evaluation run, recomendation algorithm and evaluation measure

We have used this framework to evaluate . More details about this evaluation can be found in the [paper](http://www.evazangerle.at/wp-content/papercite-data/pdf/opensym16.pdf).

# Citation and License
If you use our code in a scientific context, please cite the following paper:
```
@inProceedings{opensym16,
author = {Zangerle, Eva and Gassler, Wolfgang and Pichl, Martin and Steinhauser, Stefan and Specht, G\"{u}nther},
title = {An Empirical Evaluation of Property Recommender Systems for Wikidata and Collaborative Knowledge Bases},
booktitle = {Proceedings of the 12th International Symposium on Open Collaboration},
series = {OpenSym '16},
year = {2016},
location = {Berlin, Germany},
publisher = {ACM},
address = {New York, NY, USA}
}
```
## Getting Started 


You can find the documentation of the python evaluation part [here](http://dbisibk.github.io/PropertyRecommenderEvaluator/).


## Requirements
* Python 3.x
* MySQL or MariaDB

## Contact
Eva Zangerle, Martin Pichl, Wolfgang Gassler  
Databases and Information Systems  
Department of Computer Science  
University of Innsbruck  
firstname.lastname@uibk.ac.at  
http://dbis-informatik.uibk.ac.at  
