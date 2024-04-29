$namespace = "kube-system"
$pods = kubectl get pods -n $namespace -o=json | ConvertFrom-Json

foreach ($pod in $pods.items) {
    $nodeName = $pod.spec.nodeName
    $describeOutput = kubectl describe node $nodeName

    $outputFile = "$nodeName-describe.txt"
    $describeOutput | Out-File -FilePath $outputFile

    Write-Host "Describe output for node $nodeName saved to $outputFile"
}
