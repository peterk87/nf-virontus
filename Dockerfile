# TODO: update Dockerfile
FROM continuumio/miniconda3:4.9.2
LABEL authors="Peter Kruczkiewicz" \
      description="Docker image containing all requirements for peterk87/nf-virontus pipeline"

COPY environment.yml /
RUN apt-get update && \
    apt-get install -y procps curl && \
    apt-get clean -y && \
    conda install -c conda-forge mamba && \
    mamba env create -f /environment.yml && \
    conda clean -a
ENV PATH /opt/conda/envs/nf-virontus-2.0.0/bin:$PATH
