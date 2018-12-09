#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
pushd $DIR > /dev/null

# job chain
MODEL1=$(sbatch --parsable model1.slurm)
STUDY=$(sbatch --parsable --dependency=afterok:$MODEL1 study.slurm)
MODEL2=$(sbatch --parsable --dependency=afterok:$STUDY model2.slurm)
QUANT=$(sbatch --parsable --dependency=afterok:$MODEL2 quant.slurm)
if [ -d "bmc" ]; then
  BMC=$(sbatch --parsable --dependency=afterok:$QUANT bmc.slurm)
  DE=$(sbatch --parsable --dependency=afterok:$BMC de.slurm)
fi
EXITCODE=$?

# clean up
if [[ $EXITCODE != 0 ]]; then
  scancel $MODEL1 $STUDY $MODEL2 $QUANT $BMC $DE
  echo Failed to submit jobs!
else
  echo Submitted jobs! To cancel execute $DIR/cancel.sh
  echo '#!/bin/bash' > $DIR/cancel.sh
  echo scancel $MODEL1 $STUDY $MODEL2 $QUANT $BMC $DE >> $DIR/cancel.sh
  chmod u+x $DIR/cancel.sh
fi

popd > /dev/null
exit $EXITCODE
