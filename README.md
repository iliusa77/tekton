## Tekton Demo repository

Tekton installation
```
kubectl apply \
  --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
```

Checking pods
```
kubectl get pods -n tekton-pipelines
NAME                                          READY   STATUS    RESTARTS   AGE
tekton-events-controller-597544979-66jlk      1/1     Running   0          45s
tekton-pipelines-controller-f4bfb6cb5-2946m   1/1     Running   0          45s
tekton-pipelines-webhook-7cc9c5b5cd-k86jn     1/1     Running   0          45s
```

Check CRD
```
kubectl get crd | grep tekton
customruns.tekton.dev                        Namespaced   v1beta1(storage)            2026-09-17T12:12:51Z
pipelineruns.tekton.dev                      Namespaced   v1(storage),v1beta1         2026-09-17T12:12:51Z
pipelines.tekton.dev                         Namespaced   v1(storage),v1beta1         2026-09-17T12:12:51Z
resolutionrequests.resolution.tekton.dev     Namespaced   v1alpha1,v1beta1(storage)   2026-09-17T12:12:51Z
stepactions.tekton.dev                       Namespaced   v1alpha1,v1beta1(storage)   2026-09-17T12:12:51Z
taskruns.tekton.dev                          Namespaced   v1(storage),v1beta1         2026-09-17T12:12:51Z
tasks.tekton.dev                             Namespaced   v1(storage),v1beta1         2026-09-17T12:12:51Z
verificationpolicies.tekton.dev              Namespaced   v1alpha1(storage)           2026-09-17T12:12:51Z
```

### Simple task

Create simple task (without Git)
```
kubectl apply -f task.yaml
```

Check tasks
```
kubectl get tasks
NAME    AGE
hello   27s
```

Run TaskRun
```
kubectl apply -f taskrun.yaml
```

Check TaskRun
```
kubectl get taskrun
NAME        SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
hello-run   True        Succeeded   35s         21s
```

Check logs
```
kubectl get po
NAME            READY   STATUS      RESTARTS      AGE
hello-run-pod   0/1     Completed   0             73s

kubectl logs hello-run-pod
Defaulted container "step-hello" out of: step-hello, prepare (init), place-scripts (init)
Hello from Tekton!
```

### Pipeline

Run and check tasks
```
kubectl apply -f tasks.yaml
task.tekton.dev/build created
task.tekton.dev/test created

kubectl get tasks
NAME    AGE
build   39s
test    39s
```

Run and check pipelinerun
```
kubectl apply -f pipeline.yaml
kubectl apply -f pipelinerun.yaml
```

Check pipelinerun and taskrun
```
kubectl get pipelinerun
NAME     SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
ci-run   True        Succeeded   16s         3s

kubectl get po
NAME               READY   STATUS      RESTARTS      AGE
ci-run-build-pod   0/1     Completed   0             114s
ci-run-test-pod    0/1     Completed   0             106s
```

Tasks logs
```
kubectl logs ci-run-build-pod
Defaulted container "step-build" out of: step-build, prepare (init), place-scripts (init)
Building application...

kubectl logs ci-run-test-pod
Defaulted container "step-test" out of: step-test, prepare (init), place-scripts (init)
Running tests...
```

## Dashboard

Installation
```
kubectl apply --filename https://infra.tekton.dev/tekton-releases/dashboard/latest/release.yaml
```

Check pods and services
```
kubectl get pods -n tekton-pipelines
NAME                                          READY   STATUS    RESTARTS   AGE
tekton-dashboard-5d98f7bdfd-bmc4c             1/1     Running   0          14s

kubectl get svc -n tekton-pipelines
NAME                          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                              AGE
tekton-dashboard              ClusterIP   10.96.75.126   <none>        9097/TCP                             53s
```

Port forward
```
kubectl port-forward -n tekton-pipelines svc/tekton-dashboard 9097:9097
```

Dashboard URL: http://localhost:9097/

## Real study pipeline

```
GitHub repository
      │
      ▼
   git-clone
      │
      ▼
     test
      │
      ▼
     build
```

Install and check git-clone task
```
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.10/git-clone.yaml

kubectl get task
NAME        AGE
git-clone   15s
```

Create GitHub repo https://github.com/iliusa77/tekton.git

Run and chack test task
```
kubectl apply -f test-task.yaml

kubectl get task
NAME        AGE
run-tests   2
```

Run build task and pipeline
```
kubectl apply -f test-build-task.yaml

kubectl apply -f test-pipeline.yaml
```

Commit files in repo
```
git init
git add .
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/iliusa77/tekton.git
git push -u origin main
```

Create pvc
```
kubectl apply -f test-pvc.yaml
```

Create and check pipeline-run
```
kubectl create -f test-pipeline-run.yaml

kubectl get pipelinerun
NAME                   SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
git-test-build-hkwtv   True        Succeeded   100s        78s
```

Check PVC and pods
```
kubectl get pvc
NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
test-tekton-pvc   Bound    pvc-3bd74fde-fe91-4162-8e60-dbd65d104d4c   1Gi        RWO            standard       <unset>                 7m58s

kubectl get po
NAME                             READY   STATUS      RESTARTS      AGE
git-test-build-hkwtv-build-pod   0/1     Completed   0             34s
git-test-build-hkwtv-clone-pod   0/1     Completed   0             51s
git-test-build-hkwtv-test-pod    0/1     Completed   0             42s
```

Check logs build pod
```
kubectl logs git-test-build-hkwtv-build-pod -c step-build
Building application...
Build completed!
total 12
drwxr-xr-x    2 root     root          4096 Sep 17 13:32 .
drwxrwxrwx    4 root     root          4096 Sep 17 13:32 ..
-rw-r--r--    1 root     root            62 Sep 17 13:32 app.sh
```

Our first full-fledged Tekton CI pipeline is running successfully from start to finish. 🎉

The final result:
```
GitHub
   │
   ▼
┌─────────────┐
│    clone    │  git-clone Task
└──────┬──────┘
       │
       │ app.sh
       ▼
┌─────────────┐
│     PVC     │  shared workspace
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     test    │  run-tests Task
└──────┬──────┘
       │
       │ tests passed
       ▼
┌─────────────┐
│    build    │  build Task
└──────┬──────┘
       │
       ▼
   build/app.sh
```


## Pipeline with Docker build/push

Create build image task
```
kubectl apply -f build-image-task.yaml
```

Create secret with DockerHub credentials
```
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=YOUR_DOCKERHUB_USERNAME \
  --docker-password=YOUR_DOCKERHUB_TOKEN
```

Annotate secret
```
kubectl annotate secret dockerhub-secret \
  tekton.dev/docker-0=https://index.docker.io
```

Check secret annotations
```
kubectl describe secret dockerhub-secret
Name:         dockerhub-secret
Namespace:    default
Labels:       <none>
Annotations:  tekton.dev/docker-0: https://index.docker.io

Type:  kubernetes.io/dockerconfigjson

Data
====
.dockerconfigjson:  185 bytes
```

Create service account
```
kubectl apply -f tekton-build-sa.yaml
```

Create and check Production CI Pipeline
```
kubectl apply -f production-ci-pipeline.yaml

kubectl get pipeline
```

Create `tekton-demo` repository in https://hub.docker.com/repository/docker/iliusa77/tekton-demo

Create and get Production CI Pipeline Run
```
kubectl create -f production-ci-run.yaml

kubectl get pipelinerun
NAME                   SUCCEEDED   REASON      STARTTIME   COMPLETIONTIME
production-ci-79c5p    True        Succeeded   27s         3s
```

Check build pod status and logs
```
kubectl get po production-ci-79c5p-build-image-pod
NAME                                  READY   STATUS      RESTARTS   AGE
production-ci-79c5p-build-image-pod   0/1     Completed   0          69s

kubectl logs production-ci-79c5p-build-image-pod
Defaulted container "step-build-and-push" out of: step-build-and-push, prepare (init)
INFO[0001] Retrieving image manifest alpine:3.20        
INFO[0001] Retrieving image alpine:3.20 from registry index.docker.io 
INFO[0002] Built cross stage deps: map[]                
INFO[0002] Retrieving image manifest alpine:3.20        
INFO[0002] Returning cached image manifest              
INFO[0002] Executing 0 build triggers                   
INFO[0002] Building stage 'alpine:3.20' [idx: '0', base-idx: '-1'] 
INFO[0002] Unpacking rootfs as cmd COPY app-in-docker.sh /app/app.sh requires it. 
INFO[0003] COPY app-in-docker.sh /app/app.sh            
INFO[0003] Taking snapshot of files...                  
INFO[0003] RUN chmod +x /app/app.sh                     
INFO[0003] Initializing snapshotter ...                 
INFO[0003] Taking snapshot of full filesystem...        
INFO[0003] Cmd: /bin/sh                                 
INFO[0003] Args: [-c chmod +x /app/app.sh]              
INFO[0003] Running: [/bin/sh -c chmod +x /app/app.sh]   
INFO[0003] Taking snapshot of full filesystem...        
INFO[0003] CMD ["/app/app.sh"]                          
INFO[0003] Pushing image to docker.io/iliusa77/tekton-demo:latest 
INFO[0006] Pushed index.docker.io/iliusa77/tekton-demo@sha256:9c7f810ba2cb9fd1a9d610a7ca91da6073b1394c543df5c8f57c27974d360ff4 
```

