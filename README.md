[![Build Status](https://travis-ci.com/mxheller/code.pyret.org.svg?branch=playground)](https://travis-ci.com/mxheller/code.pyret.org)

# Data Druid: Unprompted

This README is inspired by https://github.com/brownplt/code.pyret.org

## Running Locally

### First Steps

Copy `.env.example` to `.env`.  If you want to
use the standalone pyret that comes with the checkout, set

```
PYRET="http://localhost:5000/js/cpo-main.jarr"
```

Then you can run

```
$ npm run local-install
$ ln -s node_modules/pyret-lang pyret
$ npm run build
```

and the dependencies will be installed.

### Running with Development Pyret

If you'd like to run with a development copy of Pyret, you can simply symlink
`pyret` elsewhere.  For example, if your development environment has
`code.pyret.org` and `pyret-lang` both checked out in the same directory, you
could just run this from the CPO directory:

```
$ ln -s ../pyret-lang pyret
```

### Configuration with Google Auth and Storage

In order to sign in to Druid with Google, which is required to use the tool, you need to add to your `.env` a Google client secret, a client ID, a
browser API key, a server API key, and a Heroku Redis URI.

At https://console.developers.google.com/project, make a project, then:

- For `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`, which are used for
  authenticating users:

       Credentials -> Create Credentials -> OAuth Client Id

  For development, you should set the javascript origins to
  `http://localhost:5000` and the redirect URI to
  `http://localhost:5000/oauth2callback`.

- For `GOOGLE_API_KEY`, which is used in the browser to make certain public
  requests when users are not logged in yet:

       Credentials -> Create Credentials -> API Key -> Browser Key

  Again, you should use `http://localhost:5000` as the referer for development.

Create a Heroku account at https://heroku.com, then:

1. Make a new app at https://dashboard.heroku.com.

2. Under your app's resources tab, search for `Heroku Redis` and click `Provision` in the menu that pops up.

3. Click on the `Heroku Redis` link under your add-ons and then the `View Credentials` button.

4. Copy the `URI` and use it for the environment variable `REDISCLOUD_URL`.

    *Note:* As the credentials page mentions, **this URI is not permanent**.
    If you're running the tool on heroku, as in production, it will update itself automatically, but if you're running the tool locally **you will need to occasionally update the URI with the latest from Heroku**.

### Starting the server

To run the server (you can let it running in a separate tab --
it doesn't need to be terminated across builds), run:

```
$ npm start
```

The editor will be served from `http://localhost:5000/editor`.

If you edit JavaScript or HTML files in `src/web`, run

```
$ npm run build
```

and then refresh the page.


## Setting up your own remote version of Data Druid with Heroku:

If you are doing development on Data Druid, it can be useful to run it on a remote server (for sharing purposes, etc.). Heroku allows us to do this (somewhat) easily.

### Before you begin:

* Get the [Heroku toolbelt](https://toolbelt.heroku.com/).

* Make sure you have cloned the Data Druid git repository. Then follow the instructions to get it running locally.

### To run remotely:
1. From a terminal run `heroku login`.
2. Navigate to your local Data Druid repository in a terminal.
3.	Run `heroku git:remote -a <appname>`, where `<appname>` is the name of the Heroku app you created earlier. This will link your local repository to the app.
4.	Set the config variables found in `.env` (or `.env.example`) on Heroku. You can enter them using `heroku config:set NAME1=VALUE1 NAME2=VALUE2` or in the online control panel. There are a few variables that must be changed:
    - add key `GIT_BRANCH`, value should be your branch name

    - add key `GIT_REV`, value should be your branch name

    - change `ASSET_BASE_URL`, `BASE_URL`, and `LOG_URL` from local host URLs to URLs that point to the Heroku app.

    - **change `PYRET`:** because Heroku has time limits for builds, the full build for Data Druid has to be run elsewhere.
        The way code.pyret.org does this, and the way we adopted, is to set up Travis CI to run the full build and publish `cpo-main.jarr` on Amazon S3 (CPO adds CloudFront to this as well):

        1. Create an Amazon AWS account and an S3 bucket at `https://s3.console.aws.amazon.com`.

        2. Configure Travis for your repository and use the following `.travis.yml` template, following the instructions at https://docs.travis-ci.com/user/deployment/s3/ to get your S3 access keys:
            ```yml
            language: node_js
            sudo: required
            cache:
              directories:
              - node_modules
            before_install:
            - ". $HOME/.nvm/nvm.sh"
            - nvm install stable
            - nvm use stable
            - if [[ `npm -v` != 5.2* ]]; then npm i -g npm@5.2; fi
            - export PATH=$PATH:node_modules/.bin/
            install:
            - npm install --ignore-scripts
            - npm update
            - make web
            - make deploy-cpo-main
            script:
            - echo "Build completed, deploying cpo-main.jarr to S3"
            deploy:
            - provider: s3
              access_key_id:
                secure: <ENCRYPTED ACCESS KEY ID>
              secret_access_key:
                secure: <ENCRYPTED SECRET ACCESS KEY>
              bucket: <BUCKET NAME>
              local-dir: build/web/js
              upload-dir: <TARGET DIRECTORY>
              acl: public_read
              skip_cleanup: true
              detect_encoding: true
              on:
                repo: <REPOSITORY e.g. mxheller/code.pyret.org>
                branch: <REPO BRANCH>
            ```

            `<TARGET DIRECTORY>` can be anything you want.

        3. Set `PYRET` to `https://<BUCKET NAME>.s3.amazonaws.com/<TARGET DIRECTORY>/cpo-main.jarr`.

5.	Now, still in your local repository, run `git push heroku <REPO BRANCH>:master`.

6.	Run `heroku open` or visit appname.herokuapp.com.
7.  Tips for redeploy: if you don't see a successful build under heroku webiste's activity tab, but get "everything is up-to-date" when you run `git push heroku <localbranch>:master`, or your build doesn't look up-to-date, you can do an empty commit: `git commit --allow-empty -m "force deploy"`

## Writing Assignments for Unprompted

Unprompted assignments are deployed using Google Drive's sharing features. Each assignment requires a Google Drive folder that contains all the required source files:

- `predicates.arr`
- `students.json`
- A template `.arr` file ending in `examples.arr`

See the folder `instructor-template` for a full sample folder and files.

### Deployment

To deploy an assignment, obtain the assignment's Google Drive folder ID:

1. In Google Drive, right-click on the folder and click "Get sharable link".

2. Copy the URL that is provided. Link sharing may need to be turned on.

3. The folder ID is the text immediately following `id=` in this URL. I.e., the link will look like this: `https://drive.google.com/open?id=<ID HERE>`

With the assignment's GDrive folder ID, the following URL will be a working link to the assignment (replace `Unprompted Domain` with the working domain for Unprompted):

```
https://<Unprompted Domain>/editor#template=<Assignment Folder ID>
```

Loading up the assignment will automatically create a file for the student with the same name as the template file. If such a file has already been created, it will be loaded up automatically.

*Note that users will need to log into Unprompted using a Brown email to use this module.*

### Assignment File Specifications

#### predicates.arr

This file contains all predicates and hints. Unprompted will expect certain named functions and variables to be present in the file. 

Description of required components in this file:

| Component | Type | Description |
| --------- | ---- | ----------- |
| `type-checker` | `(Any -> Boolean)` | Checks if an instance is considered valid for ths assignment. Should only return `true` for instances that are the correct data-type (or satisfy certain parameters). |
| `general-hint` | `String` | A general hint that is provided to students after certain criteria is met (See `is-general-hint-eligible`). |
| `is-general-hint-eligible` | `(Number, Number, Number -> Boolean)` | Checks if a student should be offered a general hint. *See **Hint Criteria** for information in parameters.* |
| `is-specific-hint-eligible` | `(Number, Number, Number -> Boolean)` | Checks if a student should be offered a specific hint for a predicate. *See **Hint Criteria** for information in parameters.* |


The following lines are required at the top of the source `.arr` file:

```
provide *
include shared-gdrive("playground.arr", "1sRD4hBi-TP9j_FBCg5ZZxo50rcUqFOR1")
```

##### Predicates

Predicates are written as `Predicate` instances at the top level of the `predicates.arr` file. Below is the data definition of `Predicate`:

```
data Predicate:
  | pred(f :: (Any -> Boolean), hint :: String)
end
```

The function component of `Predicate` is a Boolean function that is individually on student inputs. This function should only return `true` on student instances that satisfy the predicate.

The `hint` component is a `String` that will be displayed as a text hint for a specific predicate when hint criteria is met.

##### Hint Criteria

The conditions that are required for a user to be eligible for hints can be defined using any of the following parameters:

- `stagnated-attempts`: The number of attempts where the number of satisfied predicates has not increased.

- `num-predicates`: The total number of predicates.

- `num-satisfied-predicates`: The number of satisfied predicates.

#### students.json

This JSON describes which version of Prompted users will see. Identification of users is accomplished through the Google API, and thus uses user email. The file must have the following fields:

1. `playground`: Predicate satisfaction is not displayed to these users. Invalid data instances will still be flagged.

2. `checked`: These users will see predicate satisfaction and invalid data instance flagging.

Additionally, an optional `instructor` field can be included. These users will be provided the `checked` module in dev mode, where specific predicate satisfaction information is printed to the console for debugging.

#### Template File

This file will be loaded up as a template for users. The name of this file should end in `examples.arr` (e.g., `weather-tables-examples.arr`).

There are two required components of this file. First is the following import line exactly as is:

```
include my-gdrive("assignment")
```

Second is this exact commented line:

```
# DO NOT CHANGE ANYTHING ABOVE THIS LINE
```

The module will prevent users from editing any text above and including this comment line. Since Unprompted requires the above dummy import line in order to correctly load predicates, it is important that users are not able to edit or accidentally delete that import.
