#ifdef DARWIN
int NuMain(int argc, const char *argv[]);

int main(int argc, const char *argv[])
{
	return NuMain(argc, argv);
}
#else
int NuMain(int argc, const char *argv[], const char *envp[]);

int main(int argc, char *argv[], char *envp[])
{
    return NuMain(argc, argv, envp);
}
#endif