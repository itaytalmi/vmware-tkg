# Adding your LDAPS certificate to Harbor in TKG

>Note: in the following example, the Harbor package is installed in the `tkg-packages` namespace. If your Harbor package is installed in a different namspace, specify your namespace.

1. Modify the `overlay-harbor-ldaps-cert.yaml` overlay file and set your LDAPS/CA certificate for the `ca.crt` parameter under the `harbor-ldaps-cert` secret.

2. Create a secret from the `overlay-harbor-ldaps-cert.yaml` file:

    ```bash
    kubectl create secret generic overlay-harbor-ldaps-cert -n tkg-packages \
    --from-file=overlay-harbor-ldaps-cert.yaml \
    -o yaml --dry-run=client | kubectl apply -f -
    ```

3. Annotate the `harbor` package with the overlay:

    ```bash
    kubectl annotate packageinstalls harbor \
    ext.packaging.carvel.dev/ytt-paths-from-secret-name.0=overlay-harbor-ldaps-cert \
    -n tkg-packages
    ```

4. Trigger reconcilation for the package.

   ```bash
   kctrl app kick -a harbor -n tkg-packages -y
   ```

5. Wait for the package to reconcile.

  Confirm that the app has been successfully reconciled.

  ```bash
  kubectl get app harbor -n tkg-packages
  ```
