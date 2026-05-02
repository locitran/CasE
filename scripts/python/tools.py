def read_fasta(file_path):
    """Read a FASTA file and yield one sequence record at a time.
    Input:
    file_path (str) : Path to a FASTA file.
    Output: Yields tuples of the form: (name, sequence)
    where
    - name (str) : The FASTA header line without the leading ">"
    - sequence (str) : The full sequence joined into one string
    Notes
    -----
    - This is a generator function, so it does not return all records at once.
    - It yields one record at a time, which is memory-efficient for large FASTA files.
    """
    with open(file_path, 'r') as f:
        name, seq = None, []
        for line in f:
            line = line.strip()
            if line.startswith(">"):
                if name:
                    yield (name, "".join(seq))
                name, seq = line[1:], []
            else:
                seq.append(line)
        if name:
            yield (name, "".join(seq))

# Usage
# Q46897_fasta = 'data/Q46897.fasta'
# for name, CasE_seq in read_fasta(Q46897_fasta):
#     break