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

