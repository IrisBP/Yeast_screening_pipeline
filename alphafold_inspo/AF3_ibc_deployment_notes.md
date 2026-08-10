IBC AlphaFold3 Portal Deployment Notes

## What was added

- `alphafold3_portal_api/`
  FastAPI backend that writes job folders to the shared NAS path, submits the parent workflow job through `slurmrestd`, and l>
- `alphafold3_portal/static/`
  Workspace-local copy of the AlphaFold3 portal frontend, updated to call the backend instead of using mock jobs.
- `batch-infer-local`
  Updated to render a runtime Snakemake profile so the status script path works from the deployed repo location.
- `software/smk-simple-slurm-local/config.yaml`
  Converted to use a runtime-substituted status command.

## Files to copy where

### 1. Compute / workflow repo

Copy the updated `batch-infer-local` repo contents to the path that the SLURM parent job uses:

- Versioned release path on the cluster side:
  `/opt/ibc/alphafold3/batch-infer/releases/<version>`

- Stable symlink target used by the API:
  `/opt/ibc/alphafold3/batch-infer/current`

At minimum this deployed repo must include:

- `batch-infer-local`
- `workflow/`
- `software/smk-simple-slurm-local/`

The compute-side deployment should keep all code global, while each user job still runs from and writes back to a user-specif>

### 2. FastAPI backend

Deploy these backend files on the API host:

- `alphafold3_portal_api/`
- `alphafold3_portal/static/`

Install Python dependencies:

```bash
pip install -r alphafold3_portal_api/requirements.txt
```

Run locally for testing:

```bash
uvicorn alphafold3_portal_api.main:app --host 0.0.0.0 --port 8000
```

The frontend is then available at:

- `http://<host>:8000/alphafold3_portal/`

### 3. Apache-served frontend

If Apache should serve the static portal directly, copy:

- `alphafold3_portal/static/index.html`
- `alphafold3_portal/static/app-core.jsx`
- `alphafold3_portal/static/app.jsx`

into your Apache web directory for the AF3 portal, for example:

- `.../htdocs/alphafold3/index.html`
- `.../htdocs/alphafold3/app-core.jsx`
- `.../htdocs/alphafold3/app.jsx`

The frontend expects the backend API at:

- `/api/af3`

## Apache / FastAPI integration

Recommended Apache behavior:

- Serve `/alphafold3_portal/` as static files from `alphafold3_portal/static/`
- Reverse-proxy `/api/af3` to the FastAPI service
- Forward the authenticated Apache user to FastAPI in the header configured by:
  `IBC_AF3_REMOTE_USER_HEADER`

Current default header expected by the backend:

- `X-Remote-User`

That means Apache should pass the logged-in LDAP user like:

```apache
RequestHeader set X-Remote-User %{REMOTE_USER}s
```

## Required backend environment

Start from:

- `alphafold3_portal_api/.env.example`

The most important values are:

- `IBC_AF3_NAS_ROOT=/mnt/ibcportal_sgaussmann/alphafold3`
- `IBC_AF3_WEIGHTS_PATH=/mnt/ibcportal_sgaussmann/alphafold3/weights`
- `IBC_AF3_COMPUTE_REPO_ROOT=/opt/ibc/alphafold3/batch-infer/current`
- `IBC_AF3_SLURMRESTD_URL=http://129.132.37.167:6820/slurm/v0.0.43`
- `IBC_AF3_SLURM_USER_TOKEN=<slurmadmin JWT>`
- `IBC_AF3_PARENT_ENV_PATH=/opt/miniforge3/condabin:/opt/miniforge3/bin:/usr/local/bin:/usr/bin:/bin`

## Shared NAS layout expected by the backend

Each submitted job creates:

```text
/mnt/ibcportal_sgaussmann/alphafold3/<jobname>/
  config.yaml
  alphafold3_jsons/
    *.json
  .ibc_alphafold3_portal/
    submission.json
  .snakemake-local/
    logs/
    cluster-logs/
```

Then the workflow creates:

```text
alphafold3_msas/
alphafold3_predictions/
alphafold3_portal_parent_<jobid>.out
alphafold3_portal_parent_<jobid>.err
```

Heavy intermediate work still happens on:

```text
/mnt/local_scratch/tmp/batch-infer
```

but the user-visible Snakemake logs now land in:

```text
<jobdir>/.snakemake-local/cluster-logs/
<jobdir>/.snakemake-local/logs/
```

## Current behavior

- The backend submits to `slurmrestd` using the portal username as `X-SLURM-USER-NAME`
- The JWT token remains the `slurmadmin` token configured on the API host
- The frontend can also accept a manually entered username for testing before Apache header forwarding is in place
- Job status is derived from the shared run folder contents and parent log files

## Not implemented yet

- Per-result structure rendering inside the web UI
- Rich parsing of `ranking_scores.json` or CIF output
- Real LDAP wiring inside Apache

