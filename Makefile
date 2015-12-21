.DEFAULT_GOAL := test

.PHONY: clean compile_translations dummy_translations extract_translations fake_translations help html_coverage \
	migrate pull_translations push_translations quality requirements test update_translations validate

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  help                       display this help message"
	@echo "  clean                      delete generated byte code and coverage reports"
	@echo "  compile_translations       compile translation files, outputting .po files for each supported language"
	@echo "  dummy_translations         generate dummy translation (.po) files"
	@echo "  extract_translations       extract strings to be translated, outputting .mo files"
	@echo "  fake_translations          generate and compile dummy translation files"
	@echo "  html_coverage              generate and view HTML coverage report"
	@echo "  migrate                    apply database migrations"
	@echo "  pull_translations          pull translations from Transifex"
	@echo "  push_translations          push source translation files (.po) from Transifex"
	@echo "  quality                    run PEP8 and Pylint"
	@echo "  requirements               install requirements for production"
	@echo "  local-requirements         install requirements for local development"
	@echo "  test                       run tests and generate coverage report"
	@echo "  validate                   run tests and quality checks"
	@echo "  static                     gather all static assets for production"
	@echo "  clean_static               remove all generated static files"
	@echo "  start-devstack             run a local development copy of the server"
	@echo "  open-devstack              open a shell on the server started by start-devstack"
	@echo ""

static:
	python manage.py collectstatic --noinput

clean_static:
	rm -rf assets/ course_discovery/static/build

clean: clean_static
	find . -name '*.pyc' -delete
	coverage erase

local-requirements:
	pip install -qr requirements/local.txt --exists-action w

requirements:
	pip install -qr requirements.txt --exists-action w

test: clean
	coverage run ./manage.py test course_discovery --settings=course_discovery.settings.test
	coverage report

quality:
	pep8 --config=.pep8 course_discovery *.py
	pylint --rcfile=pylintrc course_discovery *.py

validate: test quality

migrate:
	python manage.py migrate --noinput
	python manage.py install_es_indexes

html_coverage:
	coverage html && open htmlcov/index.html

extract_translations:
	python manage.py makemessages -l en -v1 -d django
	python manage.py makemessages -l en -v1 -d djangojs

dummy_translations:
	cd course_discovery && i18n_tool dummy

compile_translations:
	python manage.py compilemessages

fake_translations: extract_translations dummy_translations compile_translations

pull_translations:
	tx pull -a

push_translations:
	tx push -s

start-devstack:
	docker-compose --x-networking up

open-devstack:
	docker-compose --x-networking up -d
	docker exec -it course-discovery env TERM=$(TERM) /edx/app/course_discovery/devstack.sh open
