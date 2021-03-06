window.createProgramCollectionAPI = function createProgramCollectionAPI(collectionName, immediate) {
  function DriveError(err) {
    this.err = err;
  }
  DriveError.prototype = Error.prototype;
  var drive;
  var SCOPE = "https://www.googleapis.com/auth/drive.file "
    + "https://spreadsheets.google.com/feeds "
    + "https://www.googleapis.com/auth/drive.appdata "
    + "https://www.googleapis.com/auth/drive.install";
  var FOLDER_MIME =  "application/vnd.google-apps.folder";
  var BACKREF_KEY = "originalProgram";
  var PUBLIC_LINK = "pubLink";

  function createAPI(baseCollection) {
    function makeSharedFile(googFileObject, fetchFromGoogle) {
      return {
        shared: true,
        getContents: function() {
          if(fetchFromGoogle) {
            // NOTE(joe): See https://developers.google.com/drive/v2/web/manage-downloads
            // The `selfLink` field directly returns the resource URL for the file, and
            // this will work as long as the file is public on the web.
            var reqUrl = googFileObject.selfLink;
            return Q($.get(reqUrl, {
              alt: "media",
              key: apiKey
            }));
          }
          else {
            return Q($.ajax("/shared-program-contents?sharedProgramId=" + googFileObject.id, {
              method: "get",
              dataType: "text"
            }));
          }
        },
        getName: function() {
          return googFileObject.title;
        },
        getModifiedTime: function() {
          return googFileObject.modifiedDate;
        },
        getUniqueId: function() {
          return googFileObject.id;
        }
      };
    }

    function makeFile(googFileObject, mimeType, fileExtension) {
      return {
        shared: false,
        getName: function() {
          return googFileObject.title;
        },
        getModifiedTime: function() {
          return googFileObject.modifiedDate;
        },
        getUniqueId: function() {
          return googFileObject.id;
        },
        getExternalURL: function() {
          return googFileObject.alternateLink;
        },
        getAssignment: function() {
          return drive.properties.get({
              "fileId": googFileObject.id,
              "propertyKey": "assignment",
              "visibility": "PUBLIC"
            }).then(function(result){return result.value;});
        },
        getShares: function() {
          return drive.files.list({
            q: "trashed=false and properties has {key='" + BACKREF_KEY + "' and value='" + googFileObject.id + "' and visibility='PRIVATE'}"
          })
            .then(function(files) {
              if(!files.items) { return []; }
              else { return files.items.map(fileBuilder); }
            });
        },
        getContents: function(cache_mode) {
          const baseUrl = "https://www.googleapis.com/drive/v3/files/" + googFileObject.id + "?alt=media&source=download";
          return fetch(baseUrl,
            { method: "get",
              cache: cache_mode || "no-cache",
              headers: new Headers([
                  ['Authorization', 'Bearer ' + gapi.auth.getToken().access_token]
                ])
            }).then(function(response) {
              return response.text();
            });
        },
        rename: function(newName) {
          return drive.files.update({
            fileId: googFileObject.id,
            resource: {
              'title': newName
            }
          }).then(fileBuilder);
        },
        makeShareCopy: function() {
          var newFile = shareCollection.then(function(c) {
            return Q($.ajax({
              url: "/create-shared-program",
              method: "post",
              data: {
                fileId: googFileObject.id,
                title: googFileObject.title,
                collectionId: c.id
              }
            }));
          });
          return newFile.then(fileBuilder);
        },
        save: function(contents, newRevision) {
          // NOTE(joe): newRevision: false will cause badRequest errors as of
          // April 30, 2014
          if(newRevision) {
            var params = { 'newRevision': true };
          }
          else {
            var params = {};
          }
          const boundary = '-------314159265358979323846';
          const delimiter = "\r\n--" + boundary + "\r\n";
          const close_delim = "\r\n--" + boundary + "--";
          var metadata = {
            'mimeType': mimeType,
            'fileExtension': fileExtension
          };
          var multipartRequestBody =
              delimiter +
              'Content-Type: application/json\r\n\r\n' +
              JSON.stringify(metadata) +
              delimiter +
              'Content-Type: text/plain\r\n' +
              '\r\n' +
              contents +
              close_delim;

          var request = gwrap.request({
            'path': '/upload/drive/v2/files/' + googFileObject.id,
            'method': 'PUT',
            'params': {'uploadType': 'multipart'},
            'headers': {
              'Content-Type': 'multipart/mixed; boundary="' + boundary + '"'
            },
            'body': multipartRequestBody});
          return request.then(fileBuilder);
        },
        _googObj: googFileObject
      };
    }

    // The primary purpose of this is to have some sort of fallback for
    // any situation in which the file object has somehow lost its info
    function fileBuilder(googFileObject) {
      if ((googFileObject.mimeType === 'text/plain' && !googFileObject.fileExtension)
          || googFileObject.fileExtension === 'arr') {
        return makeFile(googFileObject, 'text/plain', 'arr');
      } else {
        return makeFile(googFileObject, googFileObject.mimeType, googFileObject.fileExtension);
      }
    }

    let file_cache = new Map();

    var api = {
      about: function() {
        return drive.about.get({});
      },
      getCollectionLink: function() {
        return baseCollection.then(function(bc) {
          return "https://drive.google.com/drive/u/0/folders/" + bc.id;
        });
      },
      getCollectionFolderId: function() {
        return baseCollection.then(function(bc) { return bc.id; });
      },
      getFileById: function(id) {
        if (file_cache.has(id)) {
          return file_cache.get(id);
        } else {
          let req = drive.files.get({fileId: id}).then(fileBuilder);
          file_cache.set(id, req);
          return req;
        }
      },
      getFileByName: function(name) {
        return this.getAllFiles().then(function(files) {
          return files.filter(function(f) { return f.getName() === name; });
        });
      },
      getCachedFileByName: function(name) {
        return this.getCachedFiles().then(function(files) {
          return files.filter(function(f) { return f.getName() === name; });
        });
      },
      getSharedFileById: function(id) {
        var fromDrive = drive.files.get({fileId: id}, true).then(function(googFileObject) {
          return makeSharedFile(googFileObject, true);
        });
        fromDrive.catch(function(e){
          console.error("BAH", e);
        });
        var fromServer = fromDrive.fail(function() {
          return Q($.get("/shared-file", {
            sharedProgramId: id
          })).then(function(googlishFileObject) {
            return makeSharedFile(googlishFileObject, false);
          });
        });
        var result = Q.any([fromDrive, fromServer]);
        result.then(function(r) {
          console.log("Got result for shared file: ", r);
        }, function(r) {
          console.log("Got failure: ", r);
        });
        return result;
      },
      getTemplateFileById: function(id) {
        function ls(q) {
          var ret = Q.defer();
          var retrievePageOfFiles = function(request, result) {
            request.execute(function(resp) {
              result = result.concat(resp.items);
              var nextPageToken = resp.nextPageToken;
              if (nextPageToken) {
                request = gapi.client.drive.files.list({
                  'q': q,
                  'pageToken': nextPageToken
                });
                retrievePageOfFiles(request, result);
              } else {
                ret.resolve(result);
              }
            });
          }
          var initialRequest = gapi.client.drive.files.list({'q': q});
          retrievePageOfFiles(initialRequest, []);
          return ret.promise;
        }

        var sweepFromDrive =
          baseCollection.then(function(bc){
            return ls("not trashed and '" + bc.id + "' in parents and properties has { key='assignment' and value='" + id + "' and visibility='PUBLIC' }")
              .then(function(results) {
                // Load predicate file
                return ls("'"+ id + "' in parents and title contains 'predicates.arr'").then(predicateResults => {
                  window.predicateFileId = predicateResults[0].id;
                  // Load Checked/Playground email assignment file
                  window.studentToolAssignments = new Promise((resolve, reject) => {
                    ls("'"+ id + "' in parents and title contains 'students.json'")
                      .then(studentResults => {
                        return fileBuilder(studentResults[0]).getContents().then(contents => {
                          resolve(JSON.parse(contents));
                        });
                      })
                      .catch(() => {
                        resolve({});
                      });
                  });
                  if (results[0]) {
                    // load the student's work
                    return drive.files.get({"fileId": results[0].id});
                  } else {
                    // copy the template
                    return ls("'"+ id + "' in parents and title contains 'examples.arr'").then(function(results) {
                      let template = results[0];
                      return drive.files.copy({
                        "fileId": template.id,
                        "resource": {
                          "parents": [{"id": bc.id}]
                        }})
                        .then(function(file) {
                          return drive.properties.insert({
                              "fileId": file.id,
                              "resource": {
                                "key": "assignment",
                                "value": id,
                                "visibility": "PUBLIC"
                              }
                            }).then(function(_) {
                              return drive.properties.insert({
                                  "fileId": file.id,
                                  "resource": {
                                    "key": "data-druid",
                                    "value": "yes",
                                    "visibility": "PUBLIC"
                                  }});
                            }).then(function(_) {
                            return file;
                          });
                        });
                    });
                  }
                });
              })
          }).then(fileBuilder);
        return sweepFromDrive;
      },
      getFiles: function(c) {
        return c.then(function(bc) {
          return drive.files.list({ q: "trashed=false and '" + bc.id + "' in parents" })
            .then(function(filesResult) {
              if(!filesResult.items) { return []; }
              return filesResult.items.map(fileBuilder);
            });
        });
      },
      getCachedFiles: function() {
        return this.getFiles(cacheCollection);
      },
      getAllFiles: function() {
        return this.getFiles(baseCollection);
      },
      createFile: function(name, opts) {
        opts = opts || {};
        var mimeType = opts.mimeType || 'text/plain';
        var fileExtension = opts.fileExtension || 'arr';
        var collectionToSaveIn = opts.saveInCache ? cacheCollection : baseCollection;
        return collectionToSaveIn.then(function(bc) {
          var reqOpts = {
            'path': '/drive/v2/files',
            'method': 'POST',
            'params': opts.params || {},
            'body': {
              'parents': [{id: bc.id}],
              'mimeType': mimeType,
              'title': name
            }
          };
          // Allow the file extension to be omitted
          // (Google can sometime infer from the mime type)
          if (opts.fileExtension !== false) {
            reqOpts.body.fileExtension = fileExtension;
          }
          var request = gwrap.request(reqOpts);
          return request.then(fileBuilder);
        });
      },
      checkLogin: function() {
        return collection.then(function() { return true; });
      }
    };

    var shareCollection = findOrCreateDirectory(collectionName + ".shared");
    var cacheCollection = findOrCreateCacheDirectory(collectionName + ".compiled");

    return {
      api: api,
      collection: baseCollection,
      cacheCollection: cacheCollection,
      shareCollection: shareCollection,
      reinitialize: function() {
        return Q.fcall(function() { return initialize(drive); });
      }
    };
  }

  function findOrCreateDirectory(name) {
    var q = "('me' in owners) and trashed=false and title='" + name + "' and "+
        "mimeType='" + FOLDER_MIME + "'";
    var filesReq = drive.files.list({
      q: q
    });
    var collection = filesReq.then(function(files) {
      if(files.items && files.items.length > 0) {
        return files.items[0];
      }
      else {
        var dir = drive.files.insert({
          resource: {
            mimeType: FOLDER_MIME,
            title: name
          }
        });
        return dir;
      }
    });
    return collection;
  }

  function findOrCreateCacheDirectory() {
    return findOrCreateDirectory(collectionName + ".compiled");
  }

  function initialize(wrappedDrive) {
    drive = wrappedDrive;
    var baseCollection = findOrCreateDirectory(collectionName);
    return createAPI(baseCollection);
  }

  var ret = Q.defer();
  gwrap.load({name: 'drive',
              version: 'v2',
              reauth: {
                immediate: immediate
              },
              callback: function(drive) {
                ret.resolve(initialize(drive));
              }});
  return ret.promise;
}
