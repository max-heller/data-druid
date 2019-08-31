[![Build Status](https://travis-ci.com/mxheller/data-druid.svg?branch=repl-hook)](https://travis-ci.com/mxheller/data-druid)

# Data Druid: Prompted

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

## Writing Assignments for Prompted

Prompted assignments are deployed using code.pyret.org's program sharing tool (through Google Drive).

A single source file is required and can be written directly in Prompted by displaying the editor in dev mode. Dev mode can be activated in any instance of Prompted using the following web console command:

```
toggleDevMode()
```

### Deployment

To deploy an assignment:

1. In Google Drive, right-click on the `.arr` file and click "Get sharable link".

2. Copy the URL that is provided. Link sharing may need to be turned on.

3. Copy the Google Drive ID of the file, which is the text immediately following `id=` in this URL. I.e., the link will look like this: `https://drive.google.com/open?id=<ID HERE>`.

With the assignment's Google Drive ID, the following URL will be a working link to the assignment (replace `<Prompted Domain>` with the working domain for Prompted):

```
https://<Prompted Domain>/assignment/<Assignment Google Drive ID>
```
  
If any changes are made to the source file, users will need to reload the page to see changes. 

*Note that users will need to log into Prompted using a Brown email to use this module.*

### Assignment File Specifications

Prompted uses a single Pyret source file for assignments, and expects certain named variables to be present in the file. A template file, `instructor-template.arr`, is provided for convenience.

Description of required variables in the source `.arr` file:

| Component | Type | Description |
| --------- | ---- | ----------- |
| `opening-prompt` | `Any` | Contains the description to render in the first prompt. *See the **Prompt Rendering** section below.* |
| `task-list` | `List<Any; (Any -> Boolean)>` | A list of tuples containing the prompts and predicates for each task. The first element of each tuple contains the prompt to render (*See the **Prompt Rendering** section below.*), and the second provides a predicate that student answers are checked against. Student submissions will only be considered 'correct' if this predicate returns `true`. |
| `closing-prompt` | `Any` | Contains the description to render in the first prompt. *See the **Prompt Rendering** section below.* |
| `defn-start` | `Number` | Describes the line number that the instructor-provided definition begins on. |
| `defn-char-start` | `Number` | Describes the index of the character on the provided line where the instructor-provided definition starts (this value will probably be 0). |
| `defn-end` | `Number` | Describes the line number that the instructor-provided definition ends on. |
| `defn-char-end` | `Number` | Describes the index of the character on the provided line where the instructor-provided definition ends (recommended to choose an arbitrarily large number for this). |

The following import line is *required* in the source `.arr` file. However, since the `data-druid` module is specific to Prompted, this line will throw an error if you attempt to run Prompted source files in `code.pyret.org`.

```
include data-druid
```

The following code is required in the source `.arr` file as well (it is included at the end of the provided template file):

```
instructor-defn =
  make-instructor-defn(defn-start, defn-char-start, defn-end, defn-char-end)

tasks =
  get-task-list(task-list, opening-prompt, closing-prompt, some(instructor-defn))

session = state(neutral, tasks)
funs = make-funs(session)
get-current-attempt = funs.{0}
get-current-task = funs.{1}
repl-hook = funs.{2}
num-tasks = tasks.length() - 1
num-tasks-remaining = {(): session!tasks.length() - 1}
```

#### Prompt Rendering

Prompts can be provided to the module as either a `String`, a `List<Any>`, or any other data type.

If a single object is provided, it is rendered as such:

- A `String` is rendered as text with Markdown support
- An `ErrorDisplay` object is rendered directly using code.pyret.org's error rendering. This is mostly used for code embedding.
- Any other `Pyret` object is embedded directly into the prompt using code.pyret.org's fancy object rendering, the same way `Pyret` objects are rendered in the REPL.

If a `List<Any>` is provided, each element is individually rendered as above.

#### The Impossible Button

Prompted provides an `impossible` enum that can be used to build prompts that students should identify as impossible to complete. Prompts can be written to check for the `impossible` value as such:

```
{"prompt text"; _ == impossible}
```

Prompted will render a clickable `impossible` button next to each input line for every task for convenience.

#### Value Skeleton Hiding

This feature is actually built into code.pyret.org, but instructors may find it helpful for writing certain tasks. It allows instructors to write data structures that hide their contents when displayed on the REPL.

This can be especially helpful when writing tasks that ask students to retrieve information from a data structure (e.g., "get the `name` field from a `Person` object") to prevent students from cheating (typing the answer directly into the input line).

To use, import the following module:

```
import valueskeleton as VS
```

And add the following method to the data structure that should render hidden:

```
sharing:
  method _output(self):
    VS.vs-str("Output intentionally hidden.")
  end
```

*Note that `VS.vs-str("Output intentionally hidden.")` can be replaced with `VS.vs-seq(empty)` to display nothing, or any other valid `valueskeleton` rendering object.*

This method of hiding output will hide the output of *every* instance of the data structure. To maintain consistency of expected Pyret behavior for students, it is recommended that the primary data definition be left as-is and a new data definition be made for instances that need to be hidden.

For example, if students are working with a `Person` datatype, this definition would be provided for students to work with:

```
data Person:
  | person(name :: String, age :: Number)
end
```

And this definition would be used to make `Person` objects that have hidden values:

```
data Person2:
  | person2(name :: String, age :: Number)
end
```
